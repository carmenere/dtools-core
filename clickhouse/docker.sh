function ctx_docker_clickhouse() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  var BASE_IMAGE "clickhouse/clickhouse-server:23.2.5.46-alpine"
  var CLICKHOUSE_PORT 9001
  var CLICKHOUSE_HTTP_PORT 8124
  var CONTAINER "clickhouse-server"
  ctx_docker_network && ctx_docker_service && ctx_service_clickhouse || return $?
}

function docker_run_clickhouse() {
  var RUN_ENVS "CLICKHOUSE_DB CLICKHOUSE_PASSWORD CLICKHOUSE_USER CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT"
  ctx_account_admin_clickhouse && ctx_docker_clickhouse || return $?
  CLICKHOUSE_DB=${CLICKHOUSE_DB}
  CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
  CLICKHOUSE_USER=${CLICKHOUSE_USER}
  CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1
  PUBLISH=("${CLICKHOUSE_PORT}:9000/tcp")
  PUBLISH+=("${CLICKHOUSE_HTTP_PORT}:8123/tcp")
  docker_run
}

DT_BINDINGS+=(ctx_docker_clickhouse:clickhouse:docker_methods:"docker_run_clickhouse")
