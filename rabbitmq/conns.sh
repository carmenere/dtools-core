ctx_conn_rmq() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi
  if [ "${PROFILE_RMQ}" = "docker" ]; then
    load_vars ctx_docker_rmq RABBIT_HOST RABBIT_PORT RABBIT_PORT_MGM QUEUES EXCHANGES || return $?
  else
    load_vars ctx_service_rmq RABBIT_HOST RABBIT_PORT RABBIT_PORT_MGM QUEUES EXCHANGES || return $?
  fi
  ctx_epilog ${fname}
}

function ctx_conn_admin_rmq() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi
  var RABBIT_USER "guest"
  var RABBIT_PASSWORD "guest"
  ctx_conn_rmq && \
  ctx_epilog ${fname}
}

function ctx_conn_app_rmq() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi
  var RABBIT_USER "app_user"
  var RABBIT_PASSWORD 12345
  ctx_conn_rmq && \
  ctx_epilog ${fname}
}

rmq_init() { if [ "${PROFILE_RMQ}" = "docker" ]; then rmq_init_docker; else rmq_init_host; fi; }
rmq_clean() { if [ "${PROFILE_RMQ}" = "docker" ]; then rmq_clean_docker; else rmq_clean_host; fi; }

rmq_init_host() {
  service_check_rmq && \
  push_ctx ctx_conn_app_rmq || return $?
  if ! rabbitmqctl_check_user; then
    rabbitmqctl_create_user && \
    rabbitmqctl_set_user_tags && \
    rabbitmqctl_set_permissions
  fi
  pop_ctx
}

rmq_clean_host() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  service_check_rmq || return $?
  local admin=ctx_conn_admin_rmq
  local app=ctx_conn_app_rmq
  push_ctx $app || return $?
  if rabbitmqctl_check_user; then
    rabbitmqctl_drop_user && \
    rabbitmqadmin_delete $app $admin
  fi
  pop_ctx
}

rmq_init_docker() {
  local SUDO fname=$(fname "${FUNCNAME[0]}" "$0")
  docker_check_rmq && \
  push_ctx ctx_conn_app_rmq || return $?
  SUDO=
  local check_user=$(escape_quote "$(cmd_echo rabbitmqctl_check_user)")
  local create_user=$(escape_quote "$(cmd_echo rabbitmqctl_create_user)")
  local set_user_tags=$(escape_quote "$(cmd_echo rabbitmqctl_set_user_tags)")
  local set_permissions=$(escape_quote "$(cmd_echo rabbitmqctl_set_permissions)")
  if ! exec_cmd "$(docker_exec_rmq) sh -c $'${check_user}'"; then
    exec_cmd "$(docker_exec_rmq) sh -c $'${create_user}'"  && \
    exec_cmd "$(docker_exec_rmq) sh -c $'${set_user_tags}'"  && \
    exec_cmd "$(docker_exec_rmq) sh -c $'${set_permissions}'"
  fi
  pop_ctx
}

rmq_clean_docker() { docker_rm_rmq; }