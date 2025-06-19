clickhouse_exec() {
  local fname conn query_ctx=$1 conn_ctx=$2 query=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "query_ctx conn_ctx query" || return $?
  dt_debug ${fname} "query_ctx=${query_ctx}"
  open_ctx ${query_ctx} && query=$(${query}) || return $?
  dt_debug ${fname} "conn_ctx=${conn_ctx}"
  open_ctx ${conn_ctx} && conn=$(cmd_echo clickhouse_conn) || return $?
  cmd_exec "${conn} --multiquery $'${query}'"
  close_ctx
}

clickhouse_host() { if [ -n "$(CLICKHOUSE_HOST)" ]; then echo "--host $(CLICKHOUSE_HOST)"; fi; }
clickhouse_port() { if [ -n "$(CLICKHOUSE_PORT)" ]; then echo "--port $(CLICKHOUSE_PORT)"; fi; }
clickhouse_db() { if [ -n "$(CLICKHOUSE_DB)" ]; then echo "--database $(CLICKHOUSE_DB)"; fi; }
clickhouse_user() { if [ -n "$(CLICKHOUSE_USER)" ]; then echo "--user $(CLICKHOUSE_USER)"; fi; }
clickhouse_password() { if [ -n "$(CLICKHOUSE_PASSWORD)" ]; then echo "--password $(CLICKHOUSE_PASSWORD)"; fi; }
clickhouse_conn() { cmd_exec clickhouse-client $(clickhouse_host) $(clickhouse_port) $(clickhouse_db) \
    $(clickhouse_user) $(clickhouse_password); }

clickhouse_create_db() { clickhouse_exec $1 $2 clickhouse_sql_create_db; }
clickhouse_create_user() { clickhouse_exec $1 $2 clickhouse_sql_create_user; }
clickhouse_drop_db() { clickhouse_exec $1 $2 clickhouse_sql_drop_db; }
clickhouse_drop_user() { clickhouse_exec $1 $2 clickhouse_sql_drop_user; }
clickhouse_grant_user() { clickhouse_exec $1 $2 clickhouse_sql_grant_user; }

_clickhouse_init() {
  local fname admin app
  fname=$(fname "${FUNCNAME[0]}" "$0")
  admin=$1
  app=$2
  clickhouse_create_db $app $admin && \
  clickhouse_create_user $app $admin && \
  clickhouse_grant_user $app $admin
}

_clickhouse_clean() {
  local fname admin app
  fname=$(fname "${FUNCNAME[0]}" "$0")
  admin=$1
  app=$2
  clickhouse_drop_db $app $admin && \
  clickhouse_drop_user $app $admin
}
