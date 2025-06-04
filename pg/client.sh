function psql_conn() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local _envs=(PGHOST PGPORT PGUSER PGDATABASE PGPASSWORD)
  dt_err_if_empty "PG_DIR" "${PG_DIR}"; exit_on_err ${fname} $? || return $?
  local cmd=("$(dt_inline_envs "${_envs[@]}")")
  cmd+=("${PG_DIR}/psql")
  dt_exec "${cmd[@]}"
}

function psql_create_db() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty "query_ctx" "${query_ctx}"; exit_on_err ${fname} $? || return $?
  local conn_ctx=$2; dt_err_if_empty "conn_ctx" "${conn_ctx}"; exit_on_err ${fname} $? || return $?
  local query="$(${query_ctx} && pg_sql_create_db)"
  local conn="$(${conn_ctx} && dt_echo psql_conn)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec "${cmd}"
}

function psql_drop_db() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty "query_ctx" "${query_ctx}"; exit_on_err ${fname} $? || return $?
  local conn_ctx=$2; dt_err_if_empty "conn_ctx" "${conn_ctx}"; exit_on_err ${fname} $? || return $?
  local query="$(${query_ctx} && pg_sql_drop_db)"
  local conn="$(${conn_ctx} && dt_echo psql_conn)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec "${cmd}"
}

function psql_alter_role_password() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty "query_ctx" "${query_ctx}"; exit_on_err ${fname} $? || return $?
  local conn_ctx=$2; dt_err_if_empty "conn_ctx" "${conn_ctx}"; exit_on_err ${fname} $? || return $?
  local query="$(${query_ctx} && pg_sql_alter_role_password)"
  local conn="$(${conn_ctx} && dt_echo psql_conn)"
  local cmd="${conn} -c $'${query}'"
  dt_exec "${cmd}"
}

function psql_create_user() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty "query_ctx" "${query_ctx}"; exit_on_err ${fname} $? || return $?
  local conn_ctx=$2; dt_err_if_empty "conn_ctx" "${conn_ctx}"; exit_on_err ${fname} $? || return $?
  local query="$(${query_ctx} && pg_sql_create_user)"
  local conn="$(${conn_ctx} && dt_echo psql_conn)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec "${cmd}"
}

function psql_drop_user() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty "query_ctx" "${query_ctx}"; exit_on_err ${fname} $? || return $?
  local conn_ctx=$2; dt_err_if_empty "conn_ctx" "${conn_ctx}"; exit_on_err ${fname} $? || return $?
  local query="$(${query_ctx} && pg_sql_drop_user)"
  local conn="$(${conn_ctx} && dt_echo psql_conn)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec "${cmd}"
}

function psql_grant_user_app() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty "query_ctx" "${query_ctx}"; exit_on_err ${fname} $? || return $?
  local conn_ctx=$2; dt_err_if_empty "conn_ctx" "${conn_ctx}"; exit_on_err ${fname} $? || return $?
  local query="$(${query_ctx} && pg_sql_grant_user_app)"
  local conn="$(${conn_ctx} && dt_echo psql_conn)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec "${cmd}"
}

function psql_revoke_user_app() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty "query_ctx" "${query_ctx}"; exit_on_err ${fname} $? || return $?
  local conn_ctx=$2; dt_err_if_empty "conn_ctx" "${conn_ctx}"; exit_on_err ${fname} $? || return $?
  local query="$(${query_ctx} && pg_sql_revoke_user_app)"
  # Connect to db behalf 'migrator'!
  local conn="$(${conn_ctx} && dt_echo psql_conn)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec "${cmd}"
}

function psql_grant_user_migrator() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty "query_ctx" "${query_ctx}"; exit_on_err ${fname} $? || return $?
  local conn_ctx=$2; dt_err_if_empty "conn_ctx" "${conn_ctx}"; exit_on_err ${fname} $? || return $?
  local query="$(${query_ctx} && pg_sql_grant_user_migrator)"
  local conn="$(${conn_ctx} && dt_echo psql_conn)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec "${cmd}"
}

function psql_revoke_user_migrator() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty "query_ctx" "${query_ctx}"; exit_on_err ${fname} $? || return $?
  local conn_ctx=$2; dt_err_if_empty "conn_ctx" "${conn_ctx}"; exit_on_err ${fname} $? || return $?
  local query="$(${query_ctx} && pg_sql_revoke_user_migrator)"
  local conn="$(${conn_ctx} && dt_echo psql_conn)"
  local cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec "${cmd}"
}

function _psql_init() {
  (
    local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
    admin=$1; dt_err_if_empty "admin" "${admin}"; exit_on_err ${fname} $? || return $?
    migrator=$2; dt_err_if_empty "migrator" "${migrator}"; exit_on_err ${fname} $? || return $?
    app=$3; dt_err_if_empty "app" "${app}"; exit_on_err ${fname} $? || return $?
    psql_alter_role_password $admin $admin
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
    local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
    admin=$1; dt_err_if_empty "admin" "${admin}"; exit_on_err ${fname} $? || return $?
    migrator=$2; dt_err_if_empty "migrator" "${migrator}"; exit_on_err ${fname} $? || return $?
    app=$3; dt_err_if_empty "app" "${app}"; exit_on_err ${fname} $? || return $?
    psql_revoke_user_app $app $admin && \
    psql_revoke_user_migrator $migrator $admin && \
    psql_drop_db $migrator $admin && \
    psql_drop_user $app $admin && \
    psql_drop_user $migrator $admin
  )
}

function psql_conn_local_admin() {
  local cmd=$(
    ctx_conn_pg_admin
    unset PGHOST
    sudo -u ${PGUSER} psql -d ${PGDATABASE}
  )
  dt_exec "${cmd}"
}

function psql_conn_admin() {( ctx_conn_pg_admin && psql_conn )}
function psql_conn_migrator() {( ctx_conn_pg_migrator && psql_conn )}
function psql_conn_app() {( ctx_conn_pg_app && psql_conn )}

function psql_init() {(
  _psql_init ctx_conn_pg_admin ctx_conn_pg_migrator ctx_conn_pg_app
)}

function psql_clean() {(
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
function psql_clean_docker() {(
  _psql_clean ctx_conn_docker_pg_admin ctx_conn_docker_pg_migrator ctx_conn_docker_pg_app
)}

