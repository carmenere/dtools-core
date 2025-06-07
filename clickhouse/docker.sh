clickhouse_docker_vars=(${docker_vars[@]} ${clickhouse_vars[@]})

function ctx_docker_clickhouse() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=("${clickhouse_docker_vars}")
  dt_load_vars -c ctx_service_clickhouse && \
  dt_load_vars -c ctx_docker_image && \
  dt_load_vars -c ctx_docker_container && \
  dt_load_vars -c ctx_docker_network || return $?

  if [ "$(uname -m)" = "arm64" ]; then
    BASE_IMAGE="clickhouse/clickhouse-server:${MAJOR}.4.1.1943-alpine"
  else
    BASE_IMAGE="clickhouse/clickhouse-server:${MAJOR}.2.5.46-alpine"
  fi
  CLICKHOUSE_PORT=9001
  CLICKHOUSE_HTTP_PORT=8124
  PUBLISH=("${CLICKHOUSE_PORT}:9000/tcp")
  PUBLISH+=("${CLICKHOUSE_HTTP_PORT}:8123/tcp")
  CTX="."
  IMAGE=${BASE_IMAGE}
  BACKGROUND="y"
  CONTAINER="clickhouse-server"
  RESTART="always"
  CHECK_CMD="sh -c \$'clickhouse-client --query \'exit\''"
  hook_pre_docker_run=pre_docker_run_clickhouse
  dt_set_ctx -c ${ctx}
}

function pre_docker_run_clickhouse() {
  dt_load_vars -c ctx_docker_clickhouse_admin || return $?
  docker_run_envs=(CLICKHOUSE_DB CLICKHOUSE_PASSWORD CLICKHOUSE_USER CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT)
  CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1
}

dt_register "ctx_docker_clickhouse" "clickhouse" "${docker_methods[@]}"
