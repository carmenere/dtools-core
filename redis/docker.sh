function redis_docker_vars() {
  echo "$(docker_vars) $(redis_vars)" | xargs -n1 | sort -u | xargs
}

function ctx_docker_redis() {
  local ctx=$0; dt_skip_if_initialized && return 0
  dt_load_vars -c ctx_service_redis && \
  dt_load_vars -c ctx_docker_image && \
  dt_load_vars -c ctx_docker_container && \
  dt_load_vars -c ctx_docker_network || return $?
  __vars=$(redis_docker_vars)
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
  dt_set_ctx -c ${ctx}
}

dt_register "ctx_docker_redis" "redis" "${docker_methods[@]}"
