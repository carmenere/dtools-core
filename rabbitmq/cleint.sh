function rabbitmq_conn() {
  local mode=$1
  local cmd=("rabbitmqadmin")
  if [ -n "${RABBIT_HOST}" ]; then cmd+=(--host "${RABBIT_HOST}"); fi
  if [ -n "${RABBIT_PORT_MGM}" ]; then cmd+=(--port "${RABBIT_PORT_MGM}"); fi
  if [ -n "${RABBIT_USER}" ]; then cmd+=(--username "${RABBIT_USER}"); fi
  if [ -n "${RABBIT_PASSWORD}" ]; then cmd+=(--password "${RABBIT_PASSWORD}"); fi
  dt_exec_or_echo "${cmd}" $mode
}

# We do not need function "rabbitmqadmin_delete_exchanges", because application creates exchanges itself.
function rabbitmqadmin_delete_exchanges() {
  (
    local subcmd_ctx=$1; dt_err_if_empty $0 "subcmd_ctx"; exit_on_err $0 $? || return $?
    local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
    local mode=$3
    dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
    local rabbitmqadmin="$(${conn_ctx} && rabbitmq_conn echo)"
    ${subcmd_ctx}
    for exchange in $EXCHANGES; do
      dt_exec_or_echo "${rabbitmqadmin} delete exchange name='${exchange}' || true" $mode
    done
  )
}

# We do not need function "rabbitmqadmin_delete_queues", because application creates queues itself.
function rabbitmqadmin_delete_queues() {
  (
    local subcmd_ctx=$1; dt_err_if_empty $0 "subcmd_ctx"; exit_on_err $0 $? || return $?
    local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
    local mode=$3
    dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
    local rabbitmqadmin="$(${conn_ctx} && rabbitmq_conn echo)"
    ${subcmd_ctx}
    for queue in $QUEUES; do
      dt_exec_or_echo "${rabbitmqadmin} delete queue name='${queue}' || true" $mode
    done
  )
}

function rabbitmqctl_check_user() {
  local mode=$1
  ${cmd_ctx}
  local cmd="$(dt_sudo) rabbitmqctl --quiet list_users | sed -n '1d;p' | cut -d$'\t' -f1 | grep -m 1 '^${RABBIT_USER}$'"
  if [ "$mode" = "echo" ]; then; echo "${cmd}"; return 0; fi
  dt_exec "${cmd}"
}

function rabbitmqctl_create_user() {
  local mode=$1
  local cmd="$(dt_sudo) rabbitmqctl add_user ${RABBIT_USER} ${RABBIT_PASSWORD}"
  if [ "$mode" = "echo" ]; then; echo "${cmd}"; return 0; fi
  rabbitmqctl_check_user; err=$?
  if [ "${err}" = 0 ]; then
    if [ "${ERR_IF_USER_EXISTS}" = "y" ]; then
      dt_error "User '${RABBIT_USER}' exists, but ERR_IF_USER_EXISTS is set to 'y'"; return 99
    else
      dt_info "User ${BOLD} ${RABBIT_USER} exists ${RESET}, skip create."; return 0;
    fi
  fi
  dt_exec "${cmd}" $mode
}

function rabbitmqctl_drop_user() {
  local mode=$1
  local cmd="$(dt_sudo) rabbitmqctl delete_user ${RABBIT_USER}"
  if [ "$mode" = "echo" ]; then; echo "${cmd}"; return 0; fi
  rabbitmqctl_check_user; err=$?
  if [ "${err}" != 0 ]; then dt_info "User ${BOLD}${RABBIT_USER} doesn't exist${RESET}, skip drop."; return 0; fi
  dt_exec "${cmd}" $mode
}

function rabbitmqctl_set_user_tags() {
  local mode=$1
  dt_exec_or_echo "$(dt_sudo) rabbitmqctl set_user_tags ${RABBIT_USER} administrator" $mode
}

function rabbitmqctl_set_permissions() {
  local mode=$1
  dt_exec_or_echo "$(dt_sudo) rabbitmqctl set_permissions -p / ${RABBIT_USER} '.*' '.*' '.*'" $mode
}

function rabbitmq_init() {
  (
    ctx_conn_rabbitmq_app && \
      rabbitmqctl_create_user && \
      rabbitmqctl_set_user_tags && \
      rabbitmqctl_set_permissions
  )
}

function rabbitmq_clean() {
  app=ctx_conn_rabbitmq_app
  admin=ctx_conn_rabbitmq_admin
  ( ctx_conn_rabbitmq_app && rabbitmqctl_drop_user ) && \
  rabbitmqadmin_delete_exchanges $app $admin && \
  rabbitmqadmin_delete_queues $app $admin
}

function rabbitmq_init_docker() {
  docker_service_check_rabbitmq
  exec=$(docker_exec_rabbitmq echo)
  local create_user="$(ctx_conn_docker_rabbitmq_app && rabbitmqctl_create_user echo)"
  dt_exec_or_echo "$exec sh -c '$create_user'"
  local set_user_tags="$(ctx_conn_docker_rabbitmq_app && rabbitmqctl_set_user_tags echo)"
  dt_exec_or_echo "$exec sh -c '$set_user_tags'"
  local set_permissions=$(dt_escape_single_quotes "$(ctx_conn_docker_rabbitmq_app && rabbitmqctl_set_permissions echo)")
  dt_exec_or_echo "$exec sh -c $'$set_permissions'"
}

function rabbitmq_clean_docker() {
  echo "Use docker_rm_rabbitmq instead."
}