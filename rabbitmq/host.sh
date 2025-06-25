# RMQ_MODE={ host | docker }, by default "host"
# Exported to be seen in child process, if set in parent - do not change.
if [ -z "${RMQ_MODE}" ]; then export RMQ_MODE="host"; fi

rmq_mode() {
  if [ "${RMQ_MODE}" = "docker" ]; then
    echo "docker"
  elif [ "${RMQ_MODE}" = "host" ]; then
    echo "host"
  else
    dt_error ${fname} "Unknown rmq mode: RMQ_MODE=${RMQ_MODE}"
    return 99
  fi
}

set_rmq_mode_docker() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  RMQ_MODE=docker
  if is_var_changed RMQ_MODE; then drop_vars; fi && \
  dt_info ${fname} "RMQ_MODE=${RMQ_MODE}"
}

set_rmq_mode_host() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  RMQ_MODE=host
  if is_var_changed RMQ_MODE; then drop_vars; fi && \
  dt_info ${fname} "RMQ_MODE=${RMQ_MODE}"
}

function rmq_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "rabbitmq"
  else
    echo "rabbitmq-server"
  fi
}

# ctx_host_rabbitmq && rabbitmq_install
function rmq_install() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      exec_cmd "${SUDO} apt install gnupg erlang -y" && \
      exec_cmd "${SUDO} apt install rabbitmq-server -y" && \
      exec_cmd "${SUDO} sudo rabbitmq-plugins enable rabbitmq_management"
  elif [ "$(os_kernel)" = "Darwin" ]; then
    exec_cmd "brew install $(rmq_service)"
  else
    echo "Unsupported OS: '$(os_kernel)'"
  fi
}

function lsof_rmq() {
  HOST=$(RMQ_HOST); PORT=$(RMQ_PORT)
  lsof_tcp
  PORT=$(PORT_MGM)
  lsof_tcp
}

function ctx_rmq_host() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var EXCHANGES "ems" && \
  var MAJOR 3 && \
  var MINOR 8 && \
  var PATCH 3 && \
  var QUEUES 'notification ems.error ems.result ems.task' && \
  var RMQ_HOST "localhost" && \
  var RMQ_PORT 5672 && \
  var PORT_MGM 15672 && \
  var SERVICE_CHECK_CMD "rmq_conn_admin $'status' 1>/dev/null" && \
  var SERVICE $(rmq_service) && \
  var SERVICE_INSTALL "rmq_install" && \
  var SERVICE_LSOF "lsof_rmq" && \
  ctx_os_service ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_rmq_host:rmq:service_methods)
