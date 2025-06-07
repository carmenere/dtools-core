function psql_conn() {
  local fname conn_url cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  conn_url=(${pg_account[@]} ${pg_socket[@]})
  cmd=("$(dt_inline_envs "${conn_url[@]}")")
  dt_err_if_empty ${fname} "PSQL" || return $?
  cmd+=("${PSQL}")
  dt_exec ${fname} "${cmd[@]}"
}

function psql_exec() {
  local fname query_ctx conn_ctx query conn cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "query_ctx=${query_ctx}"
  query_ctx=$1; dt_err_if_empty ${fname} "query_ctx" || return $?
  conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx" || return $?
  query=$3; dt_err_if_empty ${fname} "query" || return $?
  dt_load_vars -c ${query_ctx} && \
  query=$(${query}) && \
  dt_load_vars -c ${conn_ctx} && \
  conn="$(dt_echo psql_conn)" || return $?
  cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec ${fname} "${cmd}"
}

function psql_alter_role_password() { psql_exec $1 $2 pg_sql_alter_role_password; }
function psql_create_db() { psql_exec $1 $2 pg_sql_create_db; }
function psql_create_user() { psql_exec $1 $2 pg_sql_create_user; }
function psql_drop_db() { psql_exec $1 $2 pg_sql_drop_db; }
function psql_drop_user() { psql_exec $1 $2 pg_sql_drop_user; }
function psql_grant_user_app() { psql_exec $1 $2 pg_sql_grant_user_app; }
function psql_grant_user_migrator() { psql_exec $1 $2 pg_sql_grant_user_migrator; }
function psql_revoke_user_app() { psql_exec $1 $2 pg_sql_revoke_user_app; }
function psql_revoke_user_migrator() { psql_exec $1 $2 pg_sql_revoke_user_migrator; }

function _psql_init() {
  local admin migrator app
  admin=$1
  migrator=$2
  app=$3
  psql_alter_role_password $admin $admin
  psql_create_db $migrator $admin && \
  psql_create_user $migrator $admin && \
  psql_grant_user_migrator $migrator $admin && \
  psql_create_user $app $admin && \
  # Connect to db behalf 'migrator'!
  psql_grant_user_app $app $migrator
}

function _psql_clean() {
  local admin migrator app
  admin=$1
  migrator=$2
  app=$3
  psql_revoke_user_app $app $admin && \
  psql_revoke_user_migrator $migrator $admin && \
  psql_drop_db $migrator $admin && \
  psql_drop_user $app $admin && \
  psql_drop_user $migrator $admin
}

function psql_conn_local_admin() {
  local cmd=$(
    dt_load_vars -c ctx_pg_admin || return $?
    unset PGHOST
    sudo -u ${PGUSER} psql -d ${PGDATABASE}
  )
  dt_exec ${fname} "${cmd}"
}

function psql_conn_admin() {(
  dt_load_vars -c ctx_service_pg -c ctx_pg_admin && psql_conn
)}

function psql_conn_migrator() {(
  dt_load_vars -c ctx_service_pg -c ctx_pg_migrator && psql_conn
)}

function psql_conn_app() {(
  dt_load_vars -c ctx_service_pg -c ctx_pg_app && psql_conn
)}

function psql_init() {(
  dt_load_vars -c ctx_service_pg && \
  _psql_init ctx_pg_admin ctx_pg_migrator ctx_pg_app
)}

function psql_clean() {(
  dt_load_vars -c ctx_service_pg && \
  _psql_clean ctx_pg_admin ctx_pg_migrator ctx_pg_app
)}

function psql_conn_docker_admin() {(
  docker_service_check_pg && \
  dt_load_vars -c ctx_docker_pg -c ctx_docker_pg_admin && psql_conn
)}

function psql_conn_docker_migrator() {(
  docker_service_check_pg && \
  dt_load_vars -c ctx_docker_pg -c ctx_pg_migrator && psql_conn
)}

function psql_conn_docker_app() {(
  docker_service_check_pg && \
  dt_load_vars -c ctx_docker_pg -c ctx_pg_app && psql_conn
)}

function psql_init_docker() {(
  docker_service_check_pg && \
  dt_load_vars -c ctx_docker_pg && \
  _psql_init ctx_docker_pg_admin ctx_pg_migrator ctx_pg_app
)}

# it's like docker_rm_pg && docker_run_pg
function psql_clean_docker(){(
  docker_service_check_pg && \
  dt_load_vars -c ctx_docker_pg && \
  _psql_clean ctx_docker_pg_admin ctx_pg_migrator ctx_pg_app
)}

