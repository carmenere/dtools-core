function ctx_docker_rmq() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local dt_ctx; ctx_prolog ${fname} || return $?; if is_cached ${fname}; then return 0; fi
  var BASE_IMAGE "$(docker_arm64v8)rabbitmq:3.8.3-rc.1-management-alpine"
  var CONTAINER "rabbitmq"
  var RABBIT_PORT 5672
  var RABBIT_PORT_MGM 15672
  var PUB_RABBIT_PORT 5670
  var PUB_RABBIT_PORT_MGM 15670
  var PUBLISH "$(PUB_RABBIT_PORT):$(RABBIT_PORT)/tcp $(PUB_RABBIT_PORT_MGM):$(RABBIT_PORT_MGM)/tcp"
  ctx_docker_network && ctx_docker_service && ctx_service_rmq && \
  ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_docker_rmq:rmq:docker_methods)
