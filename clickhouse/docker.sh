function ctx_docker_clickhouse() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  var BASE_IMAGE "clickhouse/clickhouse-server:23.2.5.46-alpine"
  var CLICKHOUSE_PORT 9001
  var CLICKHOUSE_HTTP_PORT 8124
  var CONTAINER "clickhouse-server"
  var SERVICE_CHECK "sh -c $'clickhouse-client --query \'exit\''"
  ctx_docker_network && ctx_docker_service && ctx_service_clickhouse && \
  ctx_epilog ${fname}
}

function docker_run_clickhouse() {
  switch_ctx ctx_docker_clickhouse || return $?
  load_vars ctx_conn_admin_clickhouse CLICKHOUSE_DB CLICKHOUSE_PASSWORD CLICKHOUSE_USER || return $?
  var RUN_ENVS "CLICKHOUSE_DB CLICKHOUSE_PASSWORD CLICKHOUSE_USER CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT"
  var CLICKHOUSE_DB $(CLICKHOUSE_DB)
  var CLICKHOUSE_PASSWORD $(CLICKHOUSE_PASSWORD)
  var CLICKHOUSE_USER $(CLICKHOUSE_USER)
  var CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT 1
  var PUBLISH "$(CLICKHOUSE_PORT):9000/tcp $(CLICKHOUSE_HTTP_PORT):8123/tcp"
  docker_run
}

DT_BINDINGS+=(ctx_docker_clickhouse:clickhouse:docker_methods:"docker_run_clickhouse")
