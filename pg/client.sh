function _psql_conn_cmd() {
  local fname=$(fname "${FUNCNAME[0]}" "$0") && \
  echo "$(inline_vars "$(pg_connurl)") $(PSQL) $@"
}

function _psql_conn() {
  local conn_ctx="$1" exec="$2" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  err_if_empty ${fname} "exec conn_ctx" && \
  shift 2 && \
  push_ctx ${conn_ctx} && \
  ${exec} $(_psql_conn_cmd $@) && \
  pop_ctx
}

function _psql_gexec() {
  local conn query_ctx="$1" conn_ctx="$2" query="$3" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  err_if_empty ${fname} "query_ctx conn_ctx query" && \
  dt_debug ${fname} "query_ctx=${query_ctx}" && \
  push_ctx ${query_ctx} && query=$(${query}) && \
  dt_debug ${fname} "conn_ctx=${conn_ctx}" && \
  push_ctx ${conn_ctx} && conn=$(_psql_conn_cmd) && \
  echo "echo $'${query}' '\gexec' | ${conn}" && \
  pop_ctx 2
}

function _psql_init() {
  local admin="$1" migrator="$2" app="$3" exec="$4" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  err_if_empty ${fname} "migrator admin app exec" && \
  ${migrator} && ${admin} && ${app} && \
  dt_debug ${fname} "admin=${admin}, migrator=${migrator}, app=${app}, exec=${exec}" && \
  ${exec} "$(_psql_gexec ${admin} ${admin} pg_sql_alter_role_password)" && \
  ${exec} "$(_psql_gexec ${migrator} ${admin} pg_sql_create_db)" && \
  ${exec} "$(_psql_gexec ${migrator} ${admin} pg_sql_create_user)" && \
  ${exec} "$(_psql_gexec ${migrator} ${admin} pg_sql_grant_user_migrator)" && \
  ${exec} "$(_psql_gexec ${app} ${admin} pg_sql_create_user)" && \
  ${exec} "$(_psql_gexec ${app} ${migrator} pg_sql_grant_user_app)"
}

function _psql_clean() {
  local admin="$1" migrator="$2" app="$3" exec="$4" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  err_if_empty ${fname} "migrator admin app exec" && \
  ${migrator} && ${admin} && ${app} && \
  dt_debug ${fname} "admin=${admin}, migrator=${migrator}, app=${app}, exec=${exec}" && \
  ${exec} "$(_psql_gexec ${app} ${admin} pg_sql_revoke_user_app)" && \
  ${exec} "$(_psql_gexec ${migrator} ${admin} pg_sql_revoke_user_migrator)" && \
  ${exec} "$(_psql_gexec ${migrator} ${admin} pg_sql_drop_db)" && \
  ${exec} "$(_psql_gexec ${migrator} ${admin} pg_sql_grant_user_migrator)" && \
  ${exec} "$(_psql_gexec ${app} ${admin} pg_sql_drop_user)" && \
  ${exec} "$(_psql_gexec ${migrator} ${admin} pg_sql_drop_user)"
}