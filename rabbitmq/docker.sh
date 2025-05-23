function ctx_docker_rabbitmq() {
  ctx_service_rabbitmq && \
  ctx_docker_image && \
  ctx_docker_container && \
  ctx_docker_network; exit_on_err $0 $? || return $?

  if [ "$(uname -m)" = "arm64" ]; then
    BASE_IMAGE="arm64v8/rabbitmq:${MAJOR}.${MINOR}.${PATCH}-rc.1-management-alpine"
  else
    BASE_IMAGE="${REGISTRY}/rabbitmq:${MAJOR}.${MINOR}.${PATCH}-rc.1-management-alpine"
  fi
  CTX="."
  IMAGE=${BASE_IMAGE}
  BACKGROUND="y"
  CONTAINER="rabbitmq"
  RABBIT_PORT=5670
  RABBIT_PORT_MGM=15670
  PUBLISH=("${RABBIT_PORT}:5672/tcp")
  PUBLISH+=("${RABBIT_PORT_MGM}:15672/tcp")
  RESTART="always"
  CHECK_CMD="sh -c 'rabbitmqctl status 1>/dev/null 2>1'"
}

function impl_docker_rabbitmq() {
  local ctx=$1; dt_err_if_empty $0 "ctx"; exit_on_err $0 $? || return $?
  local suffix=$2; dt_err_if_empty $0 "suffix"; exit_on_err $0 $? || return $?
  dt_impl "${ctx}" "${suffix}" "${docker_methods[@]}"; exit_on_err $0 $? || return $?
  eval "function docker_build_${suffix}() {( mode=\$1; $ctx && docker_pull \${mode} )}"
}

impl_docker_rabbitmq "ctx_conn_docker_rabbitmq_admin" "rabbitmq"
