function ctx_docker_rmq() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var BASE_IMAGE "$(docker_arm64v8)rabbitmq:3.8.3-rc.1-management-alpine" && \
  var SERVICE "rabbitmq" && \
  var RABBIT_PORT 5672 && \
  var RABBIT_PORT_MGM 15672 && \
  var PUB_RABBIT_PORT 5670 && \
  var PUB_RABBIT_PORT_MGM 15670 && \
  var PUBLISH "$(PUB_RABBIT_PORT):$(RABBIT_PORT)/tcp $(PUB_RABBIT_PORT_MGM):$(RABBIT_PORT_MGM)/tcp" && \
  ctx_docker_network ${caller} && ctx_docker_service ${caller} && ctx_host_rmq ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_docker_rmq:rmq:docker_methods)
