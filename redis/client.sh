function redis_conn() {
  local cmd=("redis-cli -e -u")
  cmd+=("redis://${REDIS_USER}:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}")
  dt_exec "${cmd[@]}"
}

function redis_set_requirepass() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty ${fname} "query_ctx" || return $?
  local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx" || return $?
  ${query_ctx}
  if [ "${REQUIREPASS}" != "y" ]; then return 0; fi
  local query="$(redis_ql_set_requirepass)"
  local redis_conn="$(${conn_ctx} && dt_echo redis_conn)"
  local cmd="${redis_conn} ${query}"
  dt_exec "${cmd}"
}

function redis_check_user() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty ${fname} "query_ctx" || return $?
  local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx" || return $?
  local query="$(${query_ctx} && redis_ql_check_user)"
  local redis_conn="$(${conn_ctx} && dt_echo redis_conn)"
  local cmd="${redis_conn} ${query}"
  dt_exec "${cmd}"
}

function redis_create_user() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty ${fname} "query_ctx" || return $?
  local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx" || return $?
  local query="$(${query_ctx} && redis_ql_create_user)"
  local redis_conn="$(${conn_ctx} && dt_echo redis_conn)"
  local cmd="${redis_conn} ${query}"
  dt_exec "${cmd}"
}

function redis_drop_user() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty ${fname} "query_ctx" || return $?
  local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx" || return $?
  local query="$(${query_ctx} && redis_ql_drop_user)"
  local redis_conn="$(${conn_ctx} && dt_echo redis_conn)"
  local cmd="${redis_conn} ${query}"
  dt_exec "${cmd}"
}

function redis_config_rewrite() {
  if [ "${CONFIG_REWRITE}" != "y" ]; then return 0; fi
  local redis_conn="$(dt_echo redis_conn)"
  local cmd="${redis_conn} CONFIG REWRITE"
  dt_exec "${cmd}"
}

function redis_flushall() {
  local redis_conn="$(dt_echo redis_conn)"
  local cmd="${redis_conn} FLUSHALL"
  dt_exec "${cmd}"
}

function redis_cli_init() {
  (
    admin=ctx_conn_redis_admin
    app=ctx_conn_redis_app
    redis_check_user $app $admin; err=$?
    if ! dt_exists "User" "$(${app} && echo ${REDIS_USER})" ${err}; then
      redis_create_user $app $admin && \
      redis_set_requirepass $admin $admin && \
      ${admin} && redis_config_rewrite
    fi
  )
}

function redis_cli_clean() {
  (
    admin=ctx_conn_redis_admin
    app=ctx_conn_redis_app
    redis_check_user $app $admin; err=$?
    if dt_exists "User" "$(${app} && echo ${REDIS_USER})" ${err}; then
      redis_drop_user $app $admin && \
      ${admin} && redis_flushall && \
      redis_config_rewrite
    fi
  )
}

function redis_cli_conn_admin() { ctx_conn_redis_admin && redis_conn; }
function redis_cli_conn_app() { ctx_conn_redis_app && redis_conn; }

function redis_cli_conn_docker_admin() { ctx_conn_docker_redis_admin && redis_conn; }
function redis_cli_conn_docker_app() { ctx_conn_docker_redis_app && redis_conn; }

function redis_cli_init_docker() {
  (
    admin=ctx_conn_docker_redis_admin
    app=ctx_conn_docker_redis_app
    docker_service_check_redis && \
    redis_check_user $app $admin; err=$?
    if ! dt_exists "User" "$(${app} && echo ${REDIS_USER})" ${err}; then
      redis_create_user $app $admin && \
      redis_set_requirepass $admin $admin
    fi
  )
}

function redis_cli_clean_docker() {
  echo -e "Use ${BOLD}docker_rm_redis${RESET} instead."
}

#function docker_exec_init_redis() {
#  docker_service_check_redis
#  local exec="$(ctx_docker_redis && docker_exec)"
#  local set_requirepass="$(ctx_conn_docker_redis_app && redis_set_requirepass)"
#  if [ -n "${set_requirepass}" ]; then dt_exec "${exec} ${set_requirepass}"; fi
#  local create_user="$(ctx_conn_docker_redis_app && redis_create_user)"
#  dt_exec "${exec} ${create_user}"
#}
