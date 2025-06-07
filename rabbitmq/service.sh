rabbitmq_vars=(ERR_IF_USER_EXISTS MAJOR MINOR PATCH RABBIT_HOST RABBIT_PORT RABBIT_PORT_MGM EXCHANGES QUEUES ${service[@]})

function rabbitmq_vars() {
    echo "${rabbitmq_vars[@]}" | xargs -n1 | sort -u | xargs
}

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
  STOP="$(service) stop '${SERVICE}'"
  START="$(service) start '${SERVICE}'"
  PREPARE=
  INSTALL=rabbitmq_install
  LSOF=lsof_rabbitmq
}

function ctx_service_rabbitmq() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=$(rabbitmq_vars)
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
  dt_set_ctx -c ${ctx}
}

dt_register "ctx_service_rabbitmq" "rabbitmq" "${service_methods[@]}"

function lsof_rabbitmq() {
  HOST=${RABBIT_HOST}
  PORT=${RABBIT_PORT}
  lsof_tcp
  PORT=${RABBIT_PORT_MGM}
  lsof_tcp
}
