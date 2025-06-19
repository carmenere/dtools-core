# CLICKHOUSE_PORT for clickhouse-client
# CLICKHOUSE_HTTP_PORT for applications

clickhouse_host() { if [ -n "$(CLICKHOUSE_HOST)" ]; then echo "--host $(CLICKHOUSE_HOST)"; fi; }
clickhouse_port() { if [ -n "$(CLICKHOUSE_PORT)" ]; then echo "--port $(CLICKHOUSE_PORT)"; fi; }
clickhouse_db() { if [ -n "$(CLICKHOUSE_DB)" ]; then echo "--database $(CLICKHOUSE_DB)"; fi; }
clickhouse_user() { if [ -n "$(CLICKHOUSE_USER)" ]; then echo "--user $(CLICKHOUSE_USER)"; fi; }
clickhouse_password() { if [ -n "$(CLICKHOUSE_PASSWORD)" ]; then echo "--password $(CLICKHOUSE_PASSWORD)"; fi; }
clickhouse_conn() { cmd_exec ; }

function _clickhouse_conn_cmd() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  echo "clickhouse-client $(clickhouse_host) $(clickhouse_port) $(clickhouse_db) $(clickhouse_user) $(clickhouse_password) $@"
}

function _clickhouse_conn() {
  local ser conn_ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift 1
  ser=$(select_cmd_ser ${PROFILE_CLICKHOUSE}) && \
  dt_debug ${fname} "conn_ctx=${conn_ctx}, cmd_serializer=${ser}, args=$@" && \
  err_if_empty ${fname} "ser conn_ctx" && \
  open_ctx ${conn_ctx} && \
  cmd_exec $(${ser} $(_clickhouse_conn_cmd $@)) && \
  close_ctx
}

function _clickhouse_cmd() {
  local ser conn query_ctx=$1 conn_ctx=$2 query=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "query_ctx=${query_ctx}, conn_ctx=${conn_ctx}, query=${query}" && \
  err_if_empty ${fname} "query_ctx conn_ctx query" && \
  open_ctx ${query_ctx} && query=$(${query}) && \
  ser=$(select_cmd_ser ${PROFILE_CLICKHOUSE}) && \
  dt_debug ${fname} "cmd_serializer=${ser}" && \
  err_if_empty ${fname} "ser" && \
  reopen_ctx ${conn_ctx} && conn=$(_clickhouse_conn_cmd) && \
  echo "$(${ser} "${conn} --multiquery $'${query}'")" && \
  close_ctx
}

function _clickhouse_init() {
  local ser admin=$1 app=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, app=${app}" && \
  err_if_empty ${fname} "admin app" && \
  ${admin} && ${app} && \
  cmd_exec "$(_clickhouse_cmd ${app} ${admin} clickhouse_sql_create_db)" && \
  cmd_exec "$(_clickhouse_cmd ${app} ${admin} clickhouse_sql_create_user)" && \
  cmd_exec "$(_clickhouse_cmd ${app} ${admin} clickhouse_sql_grant_user)"
}

function _clickhouse_clean() {
  local ser admin=$1 app=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, app=${app}" && \
  err_if_empty ${fname} "admin app" && \
  ${admin} && ${app} && \
  cmd_exec "$(_clickhouse_cmd ${app} ${admin} clickhouse_sql_drop_db)" && \
  cmd_exec "$(_clickhouse_cmd ${app} ${admin} clickhouse_sql_drop_user)"
}