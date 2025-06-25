function ctx_rmq_docker() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var BASE_IMAGE "$(docker_arm64v8)rabbitmq:3.8.3-rc.1-management-alpine" && \
  var SERVICE "rabbitmq" && \
  var RMQ_PORT 5672 && \
  var PORT_MGM 15672 && \
  var PUB_RMQ_PORT 5670 && \
  var PUB_PORT_MGM 15670 && \
  var PUBLISH "$(PUB_RMQ_PORT):$(RMQ_PORT)/tcp $(PUB_PORT_MGM):$(PORT_MGM)/tcp" && \
  ctx_docker_network ${caller} && ctx_docker_service ${caller} && ctx_rmq_host ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_rmq_docker:rmq:docker_methods)
