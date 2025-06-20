select_service_clickhouse() {
  if [ "${PROFILE_CLICKHOUSE}" = "docker" ]; then echo "ctx_docker_clickhouse"; else echo "ctx_service_clickhouse"; fi
}

# CLICKHOUSE_PORT for clickhouse-client
# CLICKHOUSE_HTTP_PORT for applications
clickhouse_connurl() {
  local vars=(CLICKHOUSE_DB CLICKHOUSE_HOST CLICKHOUSE_PASSWORD CLICKHOUSE_PORT CLICKHOUSE_USER)
  echo "${vars[@]}"
}

clickhouse_host() { if [ -n "$(CLICKHOUSE_HOST)" ]; then echo "--host $(CLICKHOUSE_HOST)"; fi; }
clickhouse_port() { if [ -n "$(CLICKHOUSE_PORT)" ]; then echo "--port $(CLICKHOUSE_PORT)"; fi; }
clickhouse_db() { if [ -n "$(CLICKHOUSE_DB)" ]; then echo "--database $(CLICKHOUSE_DB)"; fi; }
clickhouse_user() { if [ -n "$(CLICKHOUSE_USER)" ]; then echo "--user $(CLICKHOUSE_USER)"; fi; }
clickhouse_password() { if [ -n "$(CLICKHOUSE_PASSWORD)" ]; then echo "--password $(CLICKHOUSE_PASSWORD)"; fi; }

function _clickhouse_conn_cmd() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  echo "clickhouse-client $(clickhouse_host) $(clickhouse_port) $(clickhouse_db) $(clickhouse_user) $(clickhouse_password) $@"
}

function _clickhouse_conn() {
  local conn_ctx="$1" exec="$2" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  shift 2 && \
  err_if_empty ${fname} "exec conn_ctx" && \
  ${conn_ctx} && \
  ${exec} $(switch_ctx ${conn_ctx} && _clickhouse_conn_cmd $@)
}

function _clickhouse_cmd() {
  local conn query_ctx=$1 conn_ctx=$2 query=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "query_ctx=${query_ctx}, conn_ctx=${conn_ctx}, query=${query}" && \
  err_if_empty ${fname} "query_ctx conn_ctx query" && \
  query=$(switch_ctx ${query_ctx} && ${query}) && \
  conn=$(switch_ctx ${conn_ctx} && _clickhouse_conn_cmd) && \
  echo "${conn} --multiquery $'${query}'"
}

function _clickhouse_init() {
  local admin=$1 app=$2 exec=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, app=${app}, exec=${exec}" && \
  err_if_empty ${fname} "admin app exec" && \
  ${admin} && ${app} && \
  ${exec} "$(_clickhouse_cmd ${app} ${admin} clickhouse_sql_create_db)" && \
  ${exec} "$(_clickhouse_cmd ${app} ${admin} clickhouse_sql_create_user)" && \
  ${exec} "$(_clickhouse_cmd ${app} ${admin} clickhouse_sql_grant_user)"
}

function _clickhouse_clean() {
  local admin=$1 app=$2 exec=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, app=${app}, exec=${exec}" && \
  err_if_empty ${fname} "admin app exec" && \
  ${admin} && ${app} && \
  ${exec} "$(_clickhouse_cmd ${app} ${admin} clickhouse_sql_drop_db)" && \
  ${exec} "$(_clickhouse_cmd ${app} ${admin} clickhouse_sql_drop_user)"
}