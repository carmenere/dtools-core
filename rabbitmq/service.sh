# ctx_service_rabbitmq && rabbitmq_install
function rabbitmq_install() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      dt_exec ${fname} "${SUDO} apt install gnupg erlang -y" || return $?
      dt_exec ${fname} "${SUDO} apt install rabbitmq-server -y" || return $?
  elif [ "$(os_kernel)" = "Darwin" ]; then
    dt_exec ${fname} "brew install $(rabbitmq_service)"
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"
  fi
}

function rabbitmq_service() {
  if [ "$(os_name)" = "macos" ]; then
    SERVICE="rabbitmq"
  else
    SERVICE="rabbitmq-server"
  fi
  STOP_CMD="$(os_service) stop '${SERVICE}'"
  START_CMD="$(os_service) start '${SERVICE}'"
  PREPARE_CMD=
  INSTALL_CMD=rabbitmq_install
  LSOF=lsof_rabbitmq
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
  rabbitmq_service
}

dt_register "ctx_service_rabbitmq" "rabbitmq" "$(service_methods)"

function lsof_rabbitmq() {
  HOST=${RABBIT_HOST}
  PORT=${RABBIT_PORT}
  lsof_tcp
  PORT=${RABBIT_PORT_MGM}
  lsof_tcp
}
