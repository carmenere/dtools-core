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
  CHECK_CMD="sh -c 'redis-cli ping 1>/dev/null 2>&1'"
}

dt_register "ctx_conn_docker_redis_admin" "redis" "${docker_methods[@]}"

