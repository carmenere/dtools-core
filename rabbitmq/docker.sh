function ctx_docker_rmq() {
  var BASE_IMAGE "$(docker_arm64v8)rabbitmq:3.8.3-rc.1-management-alpine"
  var CONTAINER "rabbitmq"
  var RABBIT_PORT 5670
  var RABBIT_PORT_MGM 15670
  var PUBLISH "${RABBIT_PORT}:5672/tcp ${RABBIT_PORT_MGM}:15672/tcp"
  ctx_docker_network && ctx_docker_service && ctx_service_rmq || return $?
}

DT_BINDINGS+=(ctx_docker_rmq:rmq:docker_methods)
