function ctx_docker_redis() {
  ctx_service_redis && \
  ctx_docker_image && \
  ctx_docker_container && \
  ctx_docker_network; exit_on_err $0 $? || return $?

  if [ "$(uname -m)" = "arm64" ]; then
    BASE_IMAGE="arm64v8/redis:${MAJOR}.${MINOR}.${PATCH}-alpine3.19"
  else
    BASE_IMAGE="${REGISTRY}/xxxx/redis:${MAJOR}.${MINOR}.${PATCH}-alpine3.19"
  fi
  CTX="."
  IMAGE=${BASE_IMAGE}
  BACKGROUND="y"
  CONTAINER="redis"
  REDIS_PORT=6380
  PUBLISH+=("${REDIS_PORT}:6379/tcp")
  RESTART="always"
  CHECK_CMD="sh -c 'redis-cli ping 1>/dev/null 2>1'"
}

function impl_docker_redis() {
  local ctx=$1; dt_err_if_empty $0 "ctx"; exit_on_err $0 $? || return $?
  local suffix=$2; dt_err_if_empty $0 "suffix"; exit_on_err $0 $? || return $?
  dt_impl "${ctx}" "${suffix}" "${docker_methods[@]}"; exit_on_err $0 $? || return $?
  eval "function docker_build_${suffix}() {( mode=\$1; $ctx && docker_pull \${mode} )}"
}

impl_docker_redis "ctx_conn_docker_redis_admin" "redis"
