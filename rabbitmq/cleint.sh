function rabbitmq_conn() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  cmd=("rabbitmqadmin")
  if [ -n "${RABBIT_HOST}" ]; then cmd+=(--host "${RABBIT_HOST}"); fi
  if [ -n "${RABBIT_PORT_MGM}" ]; then cmd+=(--port "${RABBIT_PORT_MGM}"); fi
  if [ -n "${RABBIT_USER}" ]; then cmd+=(--username "${RABBIT_USER}"); fi
  if [ -n "${RABBIT_PASSWORD}" ]; then cmd+=(--password "${RABBIT_PASSWORD}"); fi
  dt_exec ${fname} "${cmd[@]}"
}

# We do not need function "rabbitmqadmin_init_exchanges", because application creates exchanges itself.
function rabbitmqadmin_delete_exchanges() {
  local fname query_ctx conn_ctx service_ctx rabbitmqadmin exchange
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  query_ctx=$1; dt_err_if_empty ${fname} "query_ctx" && \
  conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx" && \
  rabbitmqadmin="$(${app} && dt_echo rabbitmq_conn)" || return $?
  EXCHANGES=($(echo ${EXCHANGES}))
  for exchange in ${EXCHANGES[@]}; do
    dt_exec ${fname} "${rabbitmqadmin} delete exchange name='${exchange}'" || true
  done
}

# We do not need function "rabbitmqadmin_init_queues", because application creates queues itself.
function rabbitmqadmin_delete_queues() {
  local fname query_ctx conn_ctx rabbitmqadmin queue
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  query_ctx=$1; dt_err_if_empty ${fname} "query_ctx" && \
  conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx" && \
  rabbitmqadmin="$(${conn_ctx} && dt_echo rabbitmq_conn)" || return $?
  echo "QUEUES=${QUEUES}"
  QUEUES=($(echo ${QUEUES}))
  for queue in ${QUEUES[@]}; do
    dt_exec ${fname} "${rabbitmqadmin} delete queue name='${queue}'" || true
  done
}

function rabbitmqctl_check_user() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "RABBIT_USER" || return $?
  cmd="${SUDO} rabbitmqctl --quiet list_users | sed -n '1d;p' | cut -d$'\t' -f1 | grep -m 1 '^${RABBIT_USER}$'"
  dt_exec ${fname} "${cmd}"
}

function rabbitmqctl_create_user() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "RABBIT_USER" && \
  dt_err_if_empty ${fname} "RABBIT_PASSWORD" || return $?
  cmd="${SUDO} rabbitmqctl add_user ${RABBIT_USER} ${RABBIT_PASSWORD}"
  dt_exec ${fname} "${cmd}"
}

function rabbitmqctl_drop_user() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "RABBIT_USER" || return $?
  cmd="${SUDO} rabbitmqctl delete_user ${RABBIT_USER}"
  dt_exec ${fname} "${cmd}"
}

function rabbitmqctl_set_user_tags() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "RABBIT_USER" || return $?
  cmd="${SUDO} rabbitmqctl set_user_tags ${RABBIT_USER} administrator"
  dt_exec ${fname} "${cmd}"
}

function rabbitmqctl_set_permissions() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "RABBIT_USER" || return $?
  cmd="${SUDO} rabbitmqctl set_permissions -p / ${RABBIT_USER} '.*' '.*' '.*'"
  dt_exec ${fname} "${cmd}"
}

function rabbitmq_init() {(
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx_rabbitmq_app && \
  rabbitmqctl_check_user; err=$?
  if ! dt_exists "User" "${RABBIT_USER}" ${err}; then
    rabbitmqctl_create_user && \
    rabbitmqctl_set_user_tags && \
    rabbitmqctl_set_permissions
  fi
)}

function rabbitmq_clean() {(
  local fname app admin
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  app=ctx_rabbitmq_app
  admin=ctx_rabbitmq_admin
  service=ctx_service_rabbitmq
  ${app} &&  rabbitmqctl_check_user; err=$?
  if dt_exists "User" "${RABBIT_USER}" ${err}; then
    rabbitmqctl_drop_user && \
    ${service} && \
    rabbitmqadmin_delete_exchanges ${app} ${admin}  && \
    rabbitmqadmin_delete_queues ${app} ${admin}
  fi
)}

function rabbitmq_init_docker() {(
  local fname app admin check_user create_user set_user_tags set_permissions
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_service_check_rabbitmq
  ctx_rabbitmq_app || return $?
  SUDO=
  check_user=$(dt_escape_quote "$(dt_echo rabbitmqctl_check_user)")
  create_user=$(dt_escape_quote "$(dt_echo rabbitmqctl_create_user)")
  set_user_tags=$(dt_escape_quote "$(dt_echo rabbitmqctl_set_user_tags)")
  set_permissions=$(dt_escape_quote "$(dt_echo rabbitmqctl_set_permissions)")

  dt_exec ${fname} "$(docker_exec_rabbitmq) sh -c $'$check_user'"; err=$?

  if ! dt_exists "User" "${RABBIT_USER}" ${err}; then
    dt_exec ${fname} "$(docker_exec_rabbitmq) sh -c $'$create_user'"  && \
    dt_exec ${fname} "$(docker_exec_rabbitmq) sh -c $'$set_user_tags'"  && \
    dt_exec ${fname} "$(docker_exec_rabbitmq) sh -c $'$set_permissions'"
  fi
)}

function rabbitmq_clean_docker() {(
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_info ${fname} "Use ${BOLD}docker_rm_rabbitmq${RESET} instead."
)}