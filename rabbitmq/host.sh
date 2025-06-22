# PROFILE_RMQ={ host | docker }, by default "host"
if [ -z "${PROFILE_RMQ}" ]; then export PROFILE_RMQ="host"; fi

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
      exec_cmd "${SUDO} apt install gnupg erlang -y" || return $?
      exec_cmd "${SUDO} apt install rabbitmq-server -y" || return $?
  elif [ "$(os_kernel)" = "Darwin" ]; then
    exec_cmd "brew install $(rmq_service)"
  else
    echo "Unsupported OS: '$(os_kernel)'"
  fi
}

function lsof_rmq() {
  HOST=$(RABBIT_HOST); PORT=$(RABBIT_PORT)
  lsof_tcp
  PORT=$(RABBIT_PORT_MGM)
  lsof_tcp
}

function ctx_host_rmq() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var EXCHANGES "ems"
  var MAJOR 3
  var MINOR 8
  var PATCH 3
  var QUEUES 'notification ems.error ems.result ems.task'
  var RABBIT_HOST "localhost"
  var RABBIT_PORT 5672
  var RABBIT_PORT_MGM 15672
  var SERVICE_CHECK "sh -c 'rabbitmqctl status 1>/dev/null 2>&1'"
  var SERVICE $(rmq_service)
  var SERVICE_INSTALL "rmq_install"
  var SERVICE_LSOF "lsof_rmq"
  ctx_os_service ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_host_rmq:rmq:service_methods)
