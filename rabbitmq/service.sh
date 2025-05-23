function rabbitmq_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "rabbitmq"
  else
    echo "rabbitmq-server"
  fi
}

function rabbitmq_install() {
  SUDO=$(dt_sudo)
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      sudo apt install gnupg erlang -y; exit_on_err $0 $? || return $?
      sudo apt install rabbitmq-server -y; exit_on_err $0 $? || return $?
  elif [ "$(os_kernel)" = "Darwin" ]; then
    brew install $(rabbitmq_service)
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
  _export_envs=(
    ERR_IF_USER_EXISTS
    MAJOR
    MINOR
    PATCH
    RABBIT_HOST
    RABBIT_PORT
    RABBIT_PORT_MGM
  )
}

function service_stop_rabbitmq() {
  (
    local mode=$1
    ctx_service_rabbitmq && dt_exec_or_echo "$(service) stop '$(rabbitmq_service)'" $mode
  )
}

function service_start_rabbitmq() {
  (
    local mode=$1
    ctx_service_rabbitmq && dt_exec_or_echo "$(service) start '$(rabbitmq_service)'" $mode
  )
}

function service_restart_rabbitmq() {
  service_stop_rabbitmq && service_start_rabbitmq
}

function lsof_rabbitmq() {
  (
    ctx_service_rabbitmq; exit_on_err $0 $? || return $?
    HOST=${RABBIT_HOST}
    PORT=${RABBIT_PORT}
    lsof_tcp
    PORT=${RABBIT_PORT_MGM}
    lsof_tcp
  )
}
