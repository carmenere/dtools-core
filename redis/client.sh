function redis_conn() {
  local mode=$1
  local cmd=("$(dt_inline_envs)")
  cmd+=("redis-cli -e -u")
  cmd+=("redis://${REDIS_USER}:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}")
  dt_exec_or_echo "${cmd}" $mode
}

function redis_set_requirepass() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  if [ ${REQUIREPASS} != "y" ]; then return 0; fi
  local query="$(${query_ctx} && redis_ql_set_requirepass)"
  local redis_conn="$(${conn_ctx} && redis_conn echo)"
  local cmd="${redis_conn} ${query}"
  dt_exec_or_echo "$cmd" $mode
}

function redis_check_user() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && redis_ql_check_user)"
  local redis_conn="$(${conn_ctx} && redis_conn echo)"
  local cmd="${redis_conn} ${query}"
  dt_exec_or_echo "$cmd" $mode
}

function redis_create_user() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && redis_ql_create_user)"
  local redis_conn="$(${conn_ctx} && redis_conn echo)"
  if redis_check_user ${query_ctx} ${conn_ctx}; then
    dt_info "User ${BOLD}${REDIS_USER} exists${RESET}, skip create."; return 0
  fi
  local cmd="${redis_conn} ${query}"
  dt_exec_or_echo "$cmd" $mode
}

function redis_drop_user() {
  local query_ctx=$1; dt_err_if_empty $0 "query_ctx"; exit_on_err $0 $? || return $?
  local conn_ctx=$2; dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$3
  local query="$(${query_ctx} && redis_ql_drop_user)"
  local redis_conn="$(${conn_ctx} && redis_conn echo)"
  if ! redis_check_user ${query_ctx} ${conn_ctx}; then
    dt_info "User ${BOLD}${REDIS_USER} doesn't exist${RESET}, skip drop."; return 0
  fi
  local cmd="${redis_conn} ${query}"
  dt_exec_or_echo "$cmd" $mode
}

function redis_config_rewrite() {
  dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$1
  if [ ${CONFIG_REWRITE} != "y" ]; then return 0; fi
  local redis_conn="$(${conn_ctx} && redis_conn echo)"
  local cmd="${redis_conn} CONFIG REWRITE"
  dt_exec_or_echo "$cmd" $mode
}

function redis_flushall() {
  dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
  local mode=$1
  local redis_conn="$(${conn_ctx} && redis_conn echo)"
  local cmd="${redis_conn} FLUSHALL"
  dt_exec_or_echo "$cmd" $mode
}

function redis_cli_init() {
  (
    admin=ctx_conn_redis_admin
    app=ctx_conn_redis_app
    redis_set_requirepass $admin $admin && \
    redis_create_user $app $admin && \
    $app && redis_config_rewrite
  )
}

function redis_cli_clean() {
  (
    admin=ctx_conn_redis_admin
    app=ctx_conn_redis_app
    redis_drop_user $app $admin && \
    $app && redis_flushall && redis_config_rewrite
  )
}

function redis_cli_conn_admin() { redis_conn ctx_conn_redis_admin
}
function redis_cli_conn_app() { redis_conn ctx_conn_redis_app
}

function redis_cli_conn_docker_admin() { redis_conn ctx_conn_docker_redis_admin
}
function redis_cli_conn_docker_app() { redis_conn ctx_conn_docker_redis_app
}

function redis_cli_init_docker() {
  (
    admin=ctx_conn_docker_redis_admin
    app=ctx_conn_docker_redis_app
    docker_service_check_redis && \
    redis_set_requirepass $admin $admin && \
    redis_create_user $app $admin
  )
}

function redis_cli_clean_docker() {
  echo "Use docker_rm_redis instead."
}

#function docker_exec_init_redis() {
#  docker_service_check_redis
#  local exec="$(ctx_docker_redis && docker_exec echo)"
#  local set_requirepass="$(ctx_conn_docker_redis_app && redis_set_requirepass echo)"
#  if [ -n "${set_requirepass}" ]; then dt_exec_or_echo "${exec} ${set_requirepass}"; fi
#  local create_user="$(ctx_conn_docker_redis_app && redis_create_user echo)"
#  dt_exec_or_echo "${exec} ${create_user}"
#}
