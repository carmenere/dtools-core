rabbitmq_host() { if [ -n "${RABBIT_HOST}" ]; then echo "--host ${RABBIT_HOST}"; fi; }
rabbitmq_port() { if [ -n "${RABBIT_PORT_MGM}" ]; then echo "--port ${RABBIT_PORT_MGM}"; fi; }
rabbitmq_user() { if [ -n "${RABBIT_USER}" ]; then echo "--username ${RABBIT_USER}"; fi; }
rabbitmq_password() { if [ -n "${RABBIT_PASSWORD}" ]; then echo "--password ${RABBIT_PASSWORD}"; fi}

rabbitmq_conn() { cmd_exec rabbitmqadmin $(rabbitmq_host) $(rabbitmq_port) $(rabbitmq_user) $(rabbitmq_password); }

# We do not need function "rabbitmqadmin_delete_exchanges", because application creates exchanges itself.
function rabbitmqadmin_delete_exchanges() {
  (
    local fname=$(fname "${FUNCNAME[0]}" "$0")
    local subcmd_ctx=$1; err_if_empty ${fname} "subcmd_ctx" || return $?
    local conn_ctx=$2; err_if_empty ${fname} "conn_ctx" || return $?
    err_if_empty ${fname} "conn_ctx" || return $?
    local rabbitmqadmin="$(${conn_ctx} && echo rabbitmq_conn)"
    ${subcmd_ctx}
    for exchange in ${EXCHANGES[@]}; do
      cmd_exec "${rabbitmqadmin} delete exchange name='${exchange}' || true"
    done
  )
}

# We do not need function "rabbitmqadmin_delete_queues", because application creates queues itself.
function rabbitmqadmin_delete_queues() {
  (
    local fname=$(fname "${FUNCNAME[0]}" "$0")
    local subcmd_ctx=$1; err_if_empty ${fname} "subcmd_ctx" || return $?
    local conn_ctx=$2; err_if_empty ${fname} "conn_ctx" || return $?
    err_if_empty ${fname} "conn_ctx" || return $?
    local rabbitmqadmin="$(${conn_ctx} && echo rabbitmq_conn)"
    ${subcmd_ctx}
    for queue in ${QUEUES[@]}; do
      cmd_exec "${rabbitmqadmin} delete queue name='${queue}' || true"
    done
  )
}

function rabbitmqctl_check_user() {
  local cmd="${SUDO} rabbitmqctl --quiet list_users | sed -n '1d;p' | cut -d$'\t' -f1 | grep -m 1 '^${RABBIT_USER}$'"
  cmd_exec "${cmd}"
}

function rabbitmqctl_create_user() {
  local cmd="${SUDO} rabbitmqctl add_user ${RABBIT_USER} ${RABBIT_PASSWORD}"
  cmd_exec "${cmd}"
}

function rabbitmqctl_drop_user() {
  local cmd="${SUDO} rabbitmqctl delete_user ${RABBIT_USER}"
  cmd_exec "${cmd}"
}

function rabbitmqctl_set_user_tags() {
  local cmd="${SUDO} rabbitmqctl set_user_tags ${RABBIT_USER} administrator"
  cmd_exec "${cmd}"
}

function rabbitmqctl_set_permissions() {
  local cmd="${SUDO} rabbitmqctl set_permissions -p / ${RABBIT_USER} '.*' '.*' '.*'"
  cmd_exec "${cmd}"
}

function rabbitmq_init() {
  (
    local fname=$(fname "${FUNCNAME[0]}" "$0")
    ctx_conn_rabbitmq_app && rabbitmqctl_check_user; err=$?
    if ! exists "User" "${RABBIT_USER}" ${err}; then
      rabbitmqctl_create_user && \
      rabbitmqctl_set_user_tags && \
      rabbitmqctl_set_permissions
    fi
  )
}

function rabbitmq_clean() {
  (
    local fname=$(fname "${FUNCNAME[0]}" "$0")
    app=ctx_conn_rabbitmq_app
    admin=ctx_conn_rabbitmq_admin
    $app && rabbitmqctl_check_user; err=$?
    if exists "User" "${RABBIT_USER}" ${err}; then
      rabbitmqctl_drop_user && \
      rabbitmqadmin_delete_exchanges $app $admin && \
      rabbitmqadmin_delete_queues $app $admin
    fi
  )
}

function rabbitmq_init_docker() {
  (
    local fname=$(fname "${FUNCNAME[0]}" "$0")
    docker_service_check_rabbitmq
    ctx_conn_docker_rabbitmq_app
    SUDO=
    local check_user=$(escape_quote "$(echo rabbitmqctl_check_user)")
    local create_user=$(escape_quote "$(echo rabbitmqctl_create_user)")
    local set_user_tags=$(escape_quote "$(echo rabbitmqctl_set_user_tags)")
    local set_permissions=$(escape_quote "$(echo rabbitmqctl_set_permissions)")

    cmd_exec "$(docker_exec_rabbitmq) sh -c $'$check_user'"; err=$?

    if ! exists "User" "${RABBIT_USER}" ${err}; then
      cmd_exec "$(docker_exec_rabbitmq) sh -c $'$create_user'"  && \
      cmd_exec "$(docker_exec_rabbitmq) sh -c $'$set_user_tags'"  && \
      cmd_exec "$(docker_exec_rabbitmq) sh -c $'$set_permissions'"
    fi
  )
}

function rabbitmq_clean_docker() {
  echo -e "Use ${BOLD}docker_rm_rabbitmq${RESET} instead."
}