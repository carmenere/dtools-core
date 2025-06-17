function rabbitmq_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "rabbitmq"
  else
    echo "rabbitmq-server"
  fi
}

# ctx_service_rabbitmq && rabbitmq_install
function rabbitmq_install() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      cmd_exec "${SUDO} apt install gnupg erlang -y" || return $?
      cmd_exec "${SUDO} apt install rabbitmq-server -y" || return $?
  elif [ "$(os_kernel)" = "Darwin" ]; then
    cmd_exec "brew install $(rabbitmq_service)"
  else
    echo "Unsupported OS: '$(os_kernel)'"
  fi
}

function ctx_service_rabbitmq() {
  ERR_IF_USER_EXISTS="n"
  MAJOR=3
  MINOR=8
  PATCH=3
  RABBIT_HOST="localhost"
  RABBIT_PORT=5672
  RABBIT_PORT_MGM=15672
  EXCHANGES=('ems')
  QUEUES=('notification' 'ems.error' 'ems.result' 'ems.task')
  SERVICE_STOP="$(service) stop '$(rabbitmq_service)'"
  SERVICE_START="$(service) start '$(rabbitmq_service)'"
  SERVICE_PREPARE=
  SERVICE_INSTALL=rabbitmq_install
  SERVICE_LSOF=lsof_rabbitmq
}

function lsof_rabbitmq() {
  (
    HOST=${RABBIT_HOST}
    PORT=${RABBIT_PORT}
    lsof_tcp
    PORT=${RABBIT_PORT_MGM}
    lsof_tcp
  )
}

DT_BINDINGS+=(ctx_service_rabbitmq:rabbitmq:service_methods)
