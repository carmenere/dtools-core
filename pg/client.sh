function psql_conn() {
  local _inline_envs=(PGHOST PGPORT PGUSER PGDATABASE PGPASSWORD)
  dt_err_if_empty $0 "PG_DIR"; exit_on_err $0 $? || return $?
  local mode=$1
  local cmd=("$(dt_inline_envs)")
  cmd+=("${PG_DIR}/psql")
  dt_exec_or_echo "${cmd}" $mode
}

function psql_create_db() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && pg_sql_create_db)"
  local conn="$(${conn_ctx} && psql_conn echo)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec_or_echo "$cmd" $mode
}

function psql_drop_db() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && pg_sql_drop_db)"
  local conn="$(${conn_ctx} && psql_conn echo)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec_or_echo "$cmd" $mode
}

function psql_alter_role_password() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && pg_sql_alter_role_password)"
  local conn="$(${conn_ctx} && psql_conn echo)"
  local cmd="${conn} -c $'${query}'"
  dt_exec_or_echo "$cmd" $mode
}

function psql_create_user() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && pg_sql_create_user)"
  local conn="$(${conn_ctx} && psql_conn echo)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec_or_echo "$cmd" $mode
}

function psql_drop_user() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && pg_sql_drop_user)"
  local conn="$(${conn_ctx} && psql_conn echo)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec_or_echo "$cmd" $mode
}

function psql_grant_user_app() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && pg_sql_grant_user_app)"
  local conn="$(${conn_ctx} && psql_conn echo)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec_or_echo "$cmd" $mode
}

function psql_revoke_user_app() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && pg_sql_revoke_user_app)"
  # Connect to db behalf 'migrator'!
  local conn="$(${conn_ctx} && psql_conn echo)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec_or_echo "$cmd" $mode
}

function psql_grant_user_migrator() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && pg_sql_grant_user_migrator)"
  local conn="$(${conn_ctx} && psql_conn echo)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec_or_echo "$cmd" $mode
}

function psql_revoke_user_migrator() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && pg_sql_revoke_user_migrator)"
  local conn="$(${conn_ctx} && psql_conn echo)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec_or_echo "$cmd" $mode
}

function _psql_init() {
  (
    admin=$1; dt_err_if_empty $0 "admin"; exit_on_err $0 $? || return $?
    migrator=$2; dt_err_if_empty $0 "migrator"; exit_on_err $0 $? || return $?
    app=$3; dt_err_if_empty $0 "app"; exit_on_err $0 $? || return $?
    psql_alter_role_password $admin $admin && \
    psql_create_db $migrator $admin && \
    psql_create_user $migrator $admin && \
    psql_grant_user_migrator $migrator $admin && \
    psql_create_user $app $admin && \
    # Connect to db behalf 'migrator'!
    psql_grant_user_app $app $migrator
  )
}

function _psql_clean() {
  (
    admin=$1; dt_err_if_empty $0 "admin"; exit_on_err $0 $? || return $?
    migrator=$2; dt_err_if_empty $0 "migrator"; exit_on_err $0 $? || return $?
    app=$3; dt_err_if_empty $0 "app"; exit_on_err $0 $? || return $?
    psql_revoke_user_app $app $admin && \
    psql_revoke_user_migrator $migrator $admin && \
    psql_drop_db $migrator $admin && \
    psql_drop_user $app $admin && \
    psql_drop_user $migrator $admin
  )
}

function psql_conn_local_admin() {
  cmd=$(
    ctx_conn_pg_admin
    unset PGHOST
    sudo -u ${PGUSER} psql -d ${PGDATABASE}
  )
  dt_exec_or_echo "$cmd" $mode
}

function psql_conn_admin() {( ctx_conn_pg_admin && psql_conn )}
function psql_conn_migrator() {( ctx_conn_pg_migrator && psql_conn )}
function psql_conn_app() {( ctx_conn_pg_app && psql_conn )}

function psql_init() {(
  ctx_conn_pg_admin && pg_prepare && \
  _psql_init ctx_conn_pg_admin ctx_conn_pg_migrator ctx_conn_pg_app
)}

function psql_clean() {(
  ctx_conn_pg_admin && pg_prepare && \
  _psql_clean ctx_conn_pg_admin ctx_conn_pg_migrator ctx_conn_pg_app
)}

function psql_conn_docker_admin() {( ctx_conn_docker_pg_admin && psql_conn )}
function psql_conn_docker_migrator() {( ctx_conn_docker_pg_migrator && psql_conn )}
function psql_conn_docker_app() {( ctx_conn_docker_pg_app && psql_conn )}

function psql_init_docker() {(
  docker_service_check_pg && \
  _psql_init ctx_conn_docker_pg_admin ctx_conn_docker_pg_migrator ctx_conn_docker_pg_app
)}
# it's like docker_rm_pg && docker_run_pg
function psql_clean_docker() {( _psql_clean ctx_conn_docker_pg_admin ctx_conn_docker_pg_migrator ctx_conn_docker_pg_app )}

