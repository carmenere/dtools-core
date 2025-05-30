function rabbitmq_conn() {
  local mode=$1
  local cmd=("rabbitmqadmin")
  if [ -n "${RABBIT_HOST}" ]; then cmd+=(--host "${RABBIT_HOST}"); fi
  if [ -n "${RABBIT_PORT_MGM}" ]; then cmd+=(--port "${RABBIT_PORT_MGM}"); fi
  if [ -n "${RABBIT_USER}" ]; then cmd+=(--username "${RABBIT_USER}"); fi
  if [ -n "${RABBIT_PASSWORD}" ]; then cmd+=(--password "${RABBIT_PASSWORD}"); fi
  if [ "${mode}" = "echo" ]; then echo "${cmd[@]}"; else dt_exec "${cmd[@]}"; fi
}

# We do not need function "rabbitmqadmin_delete_exchanges", because application creates exchanges itself.
function rabbitmqadmin_delete_exchanges() {
  (
    local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
    local subcmd_ctx=$1; dt_err_if_empty ${fname} "subcmd_ctx"; exit_on_err ${fname} $? || return $?
    local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx"; exit_on_err ${fname} $? || return $?
    dt_err_if_empty ${fname} "conn_ctx"; exit_on_err ${fname} $? || return $?
    local rabbitmqadmin="$(${conn_ctx} && rabbitmq_conn echo)"
    ${subcmd_ctx}
    for exchange in $EXCHANGES; do
      dt_exec "${rabbitmqadmin} delete exchange name='${exchange}' || true"
    done
  )
}

# We do not need function "rabbitmqadmin_delete_queues", because application creates queues itself.
function rabbitmqadmin_delete_queues() {
  (
    local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
    local subcmd_ctx=$1; dt_err_if_empty ${fname} "subcmd_ctx"; exit_on_err ${fname} $? || return $?
    local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx"; exit_on_err ${fname} $? || return $?
    dt_err_if_empty ${fname} "conn_ctx"; exit_on_err ${fname} $? || return $?
    local rabbitmqadmin="$(${conn_ctx} && rabbitmq_conn echo)"
    ${subcmd_ctx}
    for queue in $QUEUES; do
      dt_exec "${rabbitmqadmin} delete queue name='${queue}' || true"
    done
  )
}

function rabbitmqctl_check_user() {
  local mode=$1
  local cmd="$(dt_sudo) rabbitmqctl --quiet list_users | sed -n '1d;p' | cut -d$'\t' -f1 | grep -m 1 '^${RABBIT_USER}$'"
  if [ "${mode}" = "echo" ]; then echo "${cmd}"; else dt_exec "${cmd}"; fi
}

function rabbitmqctl_create_user() {
  local mode=$1
  local cmd="$(dt_sudo) rabbitmqctl add_user ${RABBIT_USER} ${RABBIT_PASSWORD}"
  if [ "${mode}" = "echo" ]; then echo "${cmd}"; else dt_exec "${cmd}"; fi
}

function rabbitmqctl_drop_user() {
  local mode=$1
  local cmd="$(dt_sudo) rabbitmqctl delete_user ${RABBIT_USER}"
  if [ "${mode}" = "echo" ]; then echo "${cmd}"; else dt_exec "${cmd}"; fi
}

function rabbitmqctl_set_user_tags() {
  local mode=$1
  local cmd="$(dt_sudo) rabbitmqctl set_user_tags ${RABBIT_USER} administrator"
  if [ "${mode}" = "echo" ]; then echo "${cmd}"; else dt_exec "${cmd}"; fi
}

function rabbitmqctl_set_permissions() {
  local mode=$1
  local cmd="$(dt_sudo) rabbitmqctl set_permissions -p / ${RABBIT_USER} '.*' '.*' '.*'"
  if [ "${mode}" = "echo" ]; then echo "${cmd}"; else dt_exec "${cmd}"; fi
}

function rabbitmq_init() {
  (
    local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
    ctx_conn_rabbitmq_app && rabbitmqctl_check_user; err=$?
    if ! dt_exists "User" "${RABBIT_USER}" ${err}; then
      rabbitmqctl_create_user && \
      rabbitmqctl_set_user_tags && \
      rabbitmqctl_set_permissions
    fi
  )
}

function rabbitmq_clean() {
  (
    local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
    app=ctx_conn_rabbitmq_app
    admin=ctx_conn_rabbitmq_admin
    $app && rabbitmqctl_check_user; err=$?
    if dt_exists "User" "${RABBIT_USER}" ${err}; then
      rabbitmqctl_drop_user && \
      rabbitmqadmin_delete_exchanges $app $admin && \
      rabbitmqadmin_delete_queues $app $admin
    fi
  )
}

function rabbitmq_init_docker() {
  (
    local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
    docker_service_check_rabbitmq
    ctx_conn_docker_rabbitmq_app

    local check_user=$(dt_escape_single_quotes "$(rabbitmqctl_check_user echo)")
    local create_user=$(dt_escape_single_quotes "$(rabbitmqctl_create_user echo)")
    local set_user_tags=$(dt_escape_single_quotes "$(rabbitmqctl_set_user_tags echo)")
    local set_permissions=$(dt_escape_single_quotes "$(rabbitmqctl_set_permissions echo)")

    dt_exec "$(docker_exec_rabbitmq) sh -c $'$check_user'"; err=$?

    if ! dt_exists "User" "${RABBIT_USER}" ${err}; then
      dt_exec "$(docker_exec_rabbitmq) sh -c $'$create_user'"  && \
      dt_exec "$(docker_exec_rabbitmq) sh -c $'$set_user_tags'"  && \
      dt_exec "$(docker_exec_rabbitmq) sh -c $'$set_permissions'"
    fi
  )
}

function rabbitmq_clean_docker() {
  echo -e "Use ${BOLD}docker_rm_rabbitmq${RESET} instead."
}