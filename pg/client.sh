function _psql_conn_cmd() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  echo "$(inline_vars "$(pg_connurl)") $(PSQL) $@"
}

function _psql_conn() {
  local ser conn_ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift 1
  ser=$(select_cmd_ser ${PROFILE_PG}) && \
  err_if_empty ${fname} "conn_ctx ser" && \
  dt_debug ${fname} "conn_ctx=${conn_ctx}, cmd_serializer=${ser}, args=$@" && \
  open_ctx ${conn_ctx} && \
  cmd_exec $(${ser} $(_psql_conn_cmd $@)) && \
  close_ctx
}

function _psql_gexec() {
  local ser conn query_ctx=$1 conn_ctx=$2 query=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "query_ctx conn_ctx query" && \
  dt_debug ${fname} "query_ctx=${query_ctx}" && \
  open_ctx ${query_ctx} && query=$(${query}) && \
  ser=$(select_cmd_ser ${PROFILE_PG}) && \
  err_if_empty ${fname} "ser" && \
  dt_debug ${fname} "conn_ctx=${conn_ctx}, cmd_serializer=${ser}" && \
  reopen_ctx ${conn_ctx} && conn=$(_psql_conn_cmd) && \
  echo "$(${ser} "echo $'${query}' '\gexec' | ${conn}")" && \
  close_ctx
}

function _psql_init() {
  local ser admin=$1 migrator=$2 app=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "migrator admin app" && \
  ${migrator} && ${admin} && ${app} && \
  dt_debug ${fname} "admin=${admin}, migrator=${migrator}, app=${app}" && \
  cmd_exec "$(_psql_gexec ${admin} ${admin} pg_sql_alter_role_password)" && \
  cmd_exec "$(_psql_gexec ${migrator} ${admin} pg_sql_create_db)" && \
  cmd_exec "$(_psql_gexec ${migrator} ${admin} pg_sql_create_user)" && \
  cmd_exec "$(_psql_gexec ${migrator} ${admin} pg_sql_grant_user_migrator)" && \
  cmd_exec "$(_psql_gexec ${app} ${admin} pg_sql_create_user)" && \
  cmd_exec "$(_psql_gexec ${app} ${migrator} pg_sql_grant_user_app)"
}

function _psql_clean() {
  local ser admin=$1 migrator=$2 app=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "migrator admin app" && \
  ${migrator} && ${admin} && ${app} && \
  dt_debug ${fname} "admin=${admin}, migrator=${migrator}, app=${app}" && \
  cmd_exec "$(_psql_gexec ${app} ${admin} pg_sql_revoke_user_app)" && \
  cmd_exec "$(_psql_gexec ${migrator} ${admin} pg_sql_revoke_user_migrator)" && \
  cmd_exec "$(_psql_gexec ${migrator} ${admin} pg_sql_drop_db)" && \
  cmd_exec "$(_psql_gexec ${migrator} ${admin} pg_sql_grant_user_migrator)" && \
  cmd_exec "$(_psql_gexec ${app} ${admin} pg_sql_drop_user)" && \
  cmd_exec "$(_psql_gexec ${migrator} ${admin} pg_sql_drop_user)"
}