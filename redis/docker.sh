function ctx_docker_redis() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_service_redis && \
  ctx_docker_image && \
  ctx_docker_container && \
  ctx_docker_network || return $?

  if [ "$(uname -m)" = "arm64" ]; then
    BASE_IMAGE="arm64v8/redis:${MAJOR}.${MINOR}.${PATCH}-alpine3.19"
  else
    BASE_IMAGE="redis:${MAJOR}.${MINOR}.${PATCH}-alpine3.19"
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

DT_BINDINGS+=(ctx_conn_docker_redis_admin:redis:docker_methods)
