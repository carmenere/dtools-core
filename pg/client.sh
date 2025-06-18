function psql_conn() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  cmd_exec $(inline_vars "$(pg_connurl)") "$(PSQL)"
}

function psql_exec() {
  local fname conn query_ctx=$1 conn_ctx=$2 query=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "query_ctx conn_ctx query" || return $?
  dt_debug ${fname} "query_ctx=${query_ctx}"
  switch_ctx ${query_ctx}
  query=$(${query}) || return $?
  dt_debug ${fname} "conn_ctx=${conn_ctx}"
  switch_ctx ${conn_ctx}
  conn=$(cmd_echo psql_conn) || return $?
  cmd_exec "echo $'${query}' '\gexec' | ${conn}"
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
  psql_alter_role_password $admin $admin && \
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
    ctx_conn_admin_pg || return $?
    unset PGHOST
    sudo -u ${PGUSER} psql -d ${PGDATABASE}
  )
  cmd_exec "${cmd}"
}

function psql_init() {
  if [ "${PROFILE_PG}" = "docker" ]; then docker_service_check_pg || return $?; else service_check_pg || return $?; fi
  _psql_init ctx_conn_admin_pg ctx_conn_migrator_pg ctx_conn_app_pg
}

function psql_clean() {
  if [ "${PROFILE_PG}" = "docker" ]; then docker_service_check_pg || return $?; else service_check_pg || return $?; fi
  _psql_clean ctx_conn_admin_pg ctx_conn_migrator_pg ctx_conn_app_pg
}

function psql_conn_admin() { switch_ctx ctx_conn_admin_pg && psql_conn; }
function psql_conn_app() { switch_ctx ctx_conn_app_pg && psql_conn; }
function psql_conn_migrator() { switch_ctx ctx_conn_migrator_pg && psql_conn; }
