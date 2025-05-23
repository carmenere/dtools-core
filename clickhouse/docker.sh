function ctx_docker_clickhouse() {
  ctx_service_clickhouse && \
  ctx_docker_image && \
  ctx_docker_container && \
  ctx_docker_network; exit_on_err $0 $? || return $?

  if [ "$(uname -m)" = "arm64" ]; then
    BASE_IMAGE="clickhouse/clickhouse-server:${MAJOR}.4.1.1943-alpine"
  else
    BASE_IMAGE="${REGISTRY}/clickhouse/clickhouse-server:${MAJOR}.2.5.46-alpine"
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
}

function _docker_run_clickhouse() {
  CLICKHOUSE_DB=${CLICKHOUSE_DB}
  CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
  CLICKHOUSE_USER=${CLICKHOUSE_USER}
  CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1
  _run_envs=(CLICKHOUSE_DB CLICKHOUSE_PASSWORD CLICKHOUSE_USER CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT)
  docker_run; exit_on_err $0 $? || return $?
}

function impl_docker_clickhouse() {
  local ctx=$1; dt_err_if_empty $0 "ctx"; exit_on_err $0 $? || return $?
  local suffix=$2; dt_err_if_empty $0 "suffix"; exit_on_err $0 $? || return $?
  dt_impl "${ctx}" "${suffix}" "${docker_methods[@]}"; exit_on_err $0 $? || return $?
  eval "function docker_run_${suffix}() {( mode=\$1; $ctx && _docker_run_clickhouse \${mode} )}"
  eval "function docker_build_${suffix}() {( mode=\$1; $ctx && docker_pull \${mode} )}"
}

impl_docker_clickhouse "ctx_conn_docker_clickhouse_admin" "clickhouse"