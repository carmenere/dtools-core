function ctx_docker_clickhouse() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_service_clickhouse && \
  ctx_docker_image && \
  ctx_docker_container && \
  ctx_docker_network || return $?

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
  _hook_pre_docker_run=hooks_pre_docker_run_clickhouse
  _docker_run_envs=(CLICKHOUSE_DB CLICKHOUSE_PASSWORD CLICKHOUSE_USER CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT)
}

function hooks_pre_docker_run_clickhouse() {
  CLICKHOUSE_DB=${CLICKHOUSE_DB}
  CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
  CLICKHOUSE_USER=${CLICKHOUSE_USER}
  CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1
  echo "hooks_pre_docker_run_clickhouse: CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=${CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT}"
}

register "ctx_conn_docker_clickhouse_admin" "clickhouse" "${docker_methods[@]}"
