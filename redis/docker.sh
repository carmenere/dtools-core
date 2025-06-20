function ctx_docker_redis() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi
  var BASE_IMAGE "$(docker_arm64v8)redis:7.2.4-alpine3.19"
  var CONTAINER "redis"
  var REDIS_PORT 6644
  var PUBLISH "$(REDIS_PORT):6379/tcp"
  ctx_docker_network && ctx_docker_service && ctx_service_redis && \
  ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_docker_redis:redis:docker_methods)
