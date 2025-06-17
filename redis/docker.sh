function ctx_docker_redis() {
  var BASE_IMAGE "$(docker_arm64v8)redis:7.2.4-alpine3.19"
  var CHECK_CMD "sh -c 'redis-cli ping 1>/dev/null 2>&1'"
  var CONTAINER "redis"
  var REDIS_PORT 6644
  var PUBLISH "${REDIS_PORT}:6379/tcp"
  ctx_docker_network && ctx_docker_service && ctx_service_redis || return $?
}

DT_BINDINGS+=(ctx_docker_redis:redis:docker_methods)
