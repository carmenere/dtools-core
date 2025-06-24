function ctx_docker_clickhouse() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  var BASE_IMAGE "clickhouse/clickhouse-server:25.5-alpine" && \
  var CLICKHOUSE_PORT 9000 && \
  var CLICKHOUSE_HTTP_PORT 8124 && \
  var PUB_CLICKHOUSE_PORT 9300 && \
  var PUB_CLICKHOUSE_HTTP_PORT 8300 && \
  var SERVICE "clickhouse-server" && \
  var RUN_ENVS "CLICKHOUSE_DB CLICKHOUSE_PASSWORD CLICKHOUSE_USER CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT" && \
  var PUBLISH "$(PUB_CLICKHOUSE_PORT):$(CLICKHOUSE_PORT)/tcp $(PUB_CLICKHOUSE_HTTP_PORT):$(CLICKHOUSE_HTTP_PORT)/tcp" && \
  ctx_docker_network ${caller} && ctx_docker_service ${caller} && ctx_host_clickhouse ${caller} && \
  cache_ctx
}

function docker_run_clickhouse() {
  switch_ctx ctx_docker_clickhouse || return $?
  load_vars ctx_conn_admin_clickhouse CLICKHOUSE_DB CLICKHOUSE_PASSWORD CLICKHOUSE_USER || return $?
  var CLICKHOUSE_DB $(CLICKHOUSE_DB) && \
  var CLICKHOUSE_PASSWORD $(CLICKHOUSE_PASSWORD) && \
  var CLICKHOUSE_USER $(CLICKHOUSE_USER) && \
  var CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT 1 && \
  docker_run
}

DT_BINDINGS+=(ctx_docker_clickhouse:clickhouse:docker_methods:"docker_run_clickhouse")
