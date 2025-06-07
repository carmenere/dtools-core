function rabbitmq_docker_vars() {
  echo "$(docker_vars) $(rabbitmq_vars)" | xargs -n1 | sort -u | xargs
}

function ctx_docker_rabbitmq() {
  local ctx=$0; dt_skip_if_initialized && return 0
  dt_load_vars -c ctx_service_rabbitmq && \
  dt_load_vars -c ctx_docker_image && \
  dt_load_vars -c ctx_docker_container && \
  dt_load_vars -c ctx_docker_network || return $?
  __vars=$(rabbitmq_docker_vars)
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
  dt_set_ctx -c ${ctx}
}

dt_register "ctx_docker_rabbitmq" "rabbitmq" "${docker_methods[@]}"
