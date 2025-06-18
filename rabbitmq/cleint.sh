rmq_host() { if [ -n "${RABBIT_HOST}" ]; then echo "--host ${RABBIT_HOST}"; fi; }
rmq_port() { if [ -n "${RABBIT_PORT_MGM}" ]; then echo "--port ${RABBIT_PORT_MGM}"; fi; }
rmq_user() { if [ -n "${RABBIT_USER}" ]; then echo "--username ${RABBIT_USER}"; fi; }
rmq_password() { if [ -n "${RABBIT_PASSWORD}" ]; then echo "--password ${RABBIT_PASSWORD}"; fi; }

rmq_conn() { cmd_exec rabbitmqadmin $(rmq_host) $(rmq_port) $(rmq_user) $(rmq_password); }

# We do not need function "rabbitmqadmin_delete_exchanges", because application creates exchanges itself.
function rabbitmqadmin_delete_exchanges() {
  local rabbitmqadmin query_ctx=$1 conn_ctx=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "query_ctx conn_ctx" || return $?
  dt_debug ${fname} "conn_ctx=${conn_ctx}"
  rabbitmqadmin="$(${conn_ctx} && cmd_echo rmq_conn)"
  (
    dt_debug ${fname} "query_ctx=${query_ctx}"
    ${query_ctx}
    for exchange in ${EXCHANGES[@]}; do
      cmd_exec "${rabbitmqadmin} delete exchange name='${exchange}' || true"
    done
  )
}

# We do not need function "rabbitmqadmin_delete_queues", because application creates queues itself.
function rabbitmqadmin_delete_queues() {
  local rabbitmqadmin query_ctx=$1 conn_ctx=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "query_ctx conn_ctx" || return $?
  dt_debug ${fname} "conn_ctx=${conn_ctx}"
  rabbitmqadmin="$(${conn_ctx} && cmd_echo rmq_conn)"
  (
    dt_debug ${fname} "query_ctx=${query_ctx}"
    ${subcmd_ctx}
    for queue in ${QUEUES[@]}; do
      cmd_exec "${rabbitmqadmin} delete queue name='${queue}' || true"
    done
  )
}

rabbitmqctl_check_user() { cmd_exec "${SUDO} rabbitmqctl --quiet list_users | sed -n '1d;p' | cut -d$'\t' -f1 | grep -m 1 '^${RABBIT_USER}$'"; }
rabbitmqctl_create_user() { cmd_exec "${SUDO} rabbitmqctl add_user ${RABBIT_USER} ${RABBIT_PASSWORD}"; }
rabbitmqctl_drop_user() { cmd_exec "${SUDO} rabbitmqctl delete_user ${RABBIT_USER}"; }
rabbitmqctl_set_user_tags() { cmd_exec "${SUDO} rabbitmqctl set_user_tags ${RABBIT_USER} administrator"; }
rabbitmqctl_set_permissions() { cmd_exec "${SUDO} rabbitmqctl set_permissions -p / ${RABBIT_USER} '.*' '.*' '.*'"; }

rmq_init() {
  if [ "${PROFILE_RMQ}" = "docker" ]; then
    rmq_init_docker
  else
    rmq_init_host
  fi
}

rmq_clean() {
  if [ "${PROFILE_RMQ}" = "docker" ]; then
    rmq_clean_docker
  else
    rmq_clean_host
  fi
}

rmq_init_host() {
  service_check_rmq && \
  ctx_conn_app_rmq && ctx_conn_rmq || return $?
  if ! rabbitmqctl_check_user; then
    rabbitmqctl_create_user && \
    rabbitmqctl_set_user_tags && \
    rabbitmqctl_set_permissions
  fi
}

rmq_clean_host() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  service_check_rmq || return $?
  local admin=ctx_conn_admin_rmq
  local app=ctx_conn_app_rmq
  $app && ctx_conn_rmq || return $?
  if rabbitmqctl_check_user; then
    rabbitmqctl_drop_user && \
    rabbitmqadmin_delete_exchanges $app $admin && \
    rabbitmqadmin_delete_queues $app $admin
  fi
}

rmq_init_docker() {
  local SUDO fname=$(fname "${FUNCNAME[0]}" "$0")
  docker_service_check_rmq && \
  ctx_conn_app_rmq || return $?
  SUDO=
  local check_user=$(escape_quote "$(cmd_echo rabbitmqctl_check_user)")
  local create_user=$(escape_quote "$(cmd_echo rabbitmqctl_create_user)")
  local set_user_tags=$(escape_quote "$(cmd_echo rabbitmqctl_set_user_tags)")
  local set_permissions=$(escape_quote "$(cmd_echo rabbitmqctl_set_permissions)")
  if ! cmd_exec "$(docker_exec_rmq) sh -c $'${check_user}'"; then
    cmd_exec "$(docker_exec_rmq) sh -c $'${create_user}'"  && \
    cmd_exec "$(docker_exec_rmq) sh -c $'${set_user_tags}'"  && \
    cmd_exec "$(docker_exec_rmq) sh -c $'${set_permissions}'"
  fi
}

rmq_clean_docker() { docker_rm_rmq; }
