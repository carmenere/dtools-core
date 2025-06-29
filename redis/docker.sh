function ctx_redis_docker() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var BASE_IMAGE "$(docker_arm64v8)redis:7.2.4-alpine3.19" && \
  var SERVICE "redis" && \
  var REDIS_PORT 6379 && \
  var PUB_REDIS_PORT 6644 && \
  var PUBLISH "$(PUB_REDIS_PORT):$(REDIS_PORT)/tcp" && \
  ctx_docker_network ${caller} && ctx_docker_service ${caller} && ctx_redis_host ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_redis_docker:redis:docker_methods)
