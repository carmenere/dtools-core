function ctx_docker_rabbitmq() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_service_rabbitmq && \
  ctx_docker_image && \
  ctx_docker_container && \
  ctx_docker_network || return $?

  if [ "$(uname -m)" = "arm64" ]; then
    BASE_IMAGE="arm64v8/rabbitmq:${MAJOR}.${MINOR}.${PATCH}-rc.1-management-alpine"
  else
    BASE_IMAGE="rabbitmq:${MAJOR}.${MINOR}.${PATCH}-rc.1-management-alpine"
  fi
  CTX="."
  IMAGE=${BASE_IMAGE}
  BACKGROUND="y"
  CONTAINER="rabbitmq"
  RABBIT_PORT=5670
  RABBIT_PORT_MGM=15670
  PUBLISH=("${RABBIT_PORT}:5672/tcp")
  PUBLISH+=("${RABBIT_PORT_MGM}:15672/tcp")
  RESTART="always"
  CHECK_CMD="sh -c 'rabbitmqctl status 1>/dev/null 2>&1'"
}

register "ctx_conn_docker_rabbitmq_admin" "rabbitmq" "${docker_methods[@]}"
