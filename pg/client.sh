pg_connurl() {
  local vars=(PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER)
  echo "${vars[@]}"
}

function _psql_conn() {
  echo "$(inline_vars "$(pg_connurl)") $(PSQL) $@"
}

function _psql_gexec() {
  local query_ctx="$1" conn_ctx="$2" query="$3" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  dt_debug ${fname} "query_ctx=${query_ctx}, conn_ctx=${conn_ctx}, query=${query}" && \
  err_if_empty ${fname} "query_ctx conn_ctx query" && \
  switch_ctx ${query_ctx} && \
  query=$(${query}) && \
  local exec=$(EXEC) && \
  switch_ctx ${conn_ctx} && \
  ${exec} "echo $'${query}' '\gexec' | $(_psql_conn)"
}

function _psql_init() {
  dt_warning _psql_init "admin=${admin} admin=${admin}" && \

  _psql_gexec ${admin} ${admin} pg_sql_alter_role_password && \
  _psql_gexec ${migrator} ${admin} pg_sql_create_db && \
  _psql_gexec ${migrator} ${admin} pg_sql_create_user && \
  _psql_gexec ${migrator} ${admin} pg_sql_grant_user_migrator && \
  _psql_gexec ${app} ${admin} pg_sql_create_user && \
  _psql_gexec ${app} ${migrator} pg_sql_grant_user_app
}

function _psql_clean() {
  _psql_gexec ${app} ${admin} pg_sql_revoke_user_app && \
  _psql_gexec ${migrator} ${admin} pg_sql_revoke_user_migrator && \
  _psql_gexec ${migrator} ${admin} pg_sql_drop_db && \
  _psql_gexec ${app} ${admin} pg_sql_drop_user && \
  _psql_gexec ${migrator} ${admin} pg_sql_drop_user
}

function psql_conn() {
  $(CONN) "$(inline_vars "$(pg_connurl)") $(PSQL) $@"
}

function psql_methods() {
  local methods=()
  methods+=(psql_conn)
  echo "${methods[@]}"
}