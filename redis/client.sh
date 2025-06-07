function redis_exec() {
  local fname query_ctx conn_ctx query conn cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "query_ctx=${query_ctx}"
  query_ctx=$1; dt_err_if_empty ${fname} "query_ctx" || return $?
  conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx" || return $?
  query=$3; dt_err_if_empty ${fname} "query" || return $?
  dt_load_vars -c ${query_ctx} && \
  query=$(${query}) && \
  dt_load_vars -c ${conn_ctx} && \
  conn="$(dt_echo redis_conn)" || return $?
  cmd="${conn} ${query}"
  dt_exec ${fname} "${cmd}"
}

function redis_conn() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local cmd=("redis-cli -e -u")
  cmd+=("redis://${REDIS_USER}:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}")
  dt_exec ${fname} "${cmd[@]}"
}

function redis_set_requirepass() {
  if [ "${REQUIREPASS}" != "y" ]; then return 0; fi
  redis_exec $1 $2 redis_ql_set_requirepass
}

function redis_check_user() { redis_exec $1 $2 redis_ql_check_user; }
function redis_create_user() { redis_exec $1 $2 redis_ql_create_user; }
function redis_drop_user() { redis_exec $1 $2 redis_ql_drop_user; }

function redis_config_rewrite() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "${CONFIG_REWRITE}" != "y" ]; then return 0; fi
  dt_exec ${fname} "$(dt_echo redis_conn) CONFIG REWRITE"
}

function redis_flushall() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local redis_conn="$(dt_echo redis_conn)"
  local cmd="${redis_conn} FLUSHALL"
  dt_exec ${fname} "${cmd}"
}

function redis_cli_init() {
  admin=ctx_redis_admin
  app=ctx_redis_app
  redis_check_user ${app} ${admin}; err=$?
  if ! dt_exists "User" "$(${app} && echo ${REDIS_USER})" ${err}; then
    redis_create_user ${app} ${admin} && \
    dt_load_vars -c ${admin} && \
    redis_set_requirepass ${admin} ${admin} && \
    redis_config_rewrite
  fi
}

function redis_cli_clean() {
  admin=ctx_redis_admin
  app=ctx_redis_app
  redis_check_user ${app} ${admin}; err=$?
  if dt_exists "User" "$(${app} && echo ${REDIS_USER})" ${err}; then
    redis_drop_user ${app} ${admin} && \
    dt_load_vars -c ${admin} && \
    redis_flushall && \
    redis_config_rewrite
  fi
}

function redis_cli_conn_admin() {( dt_load_vars -c ctx_redis_admin && redis_conn; )}
function redis_cli_conn_app() {( dt_load_vars -c ctx_redis_app && redis_conn; )}
function redis_cli_conn_docker_admin() {( dt_load_vars -c ctx_redis_admin && redis_conn; )}
function redis_cli_conn_docker_app() {( dt_load_vars -c ctx_redis_app && redis_conn; )}

function redis_cli_init_docker() {(
  admin=ctx_redis_admin
  app=ctx_redis_app
  docker_service_check_redis && \
  redis_check_user ${app} ${admin}; err=$?
  if ! dt_exists "User" "$(${app} && echo ${REDIS_USER})" ${err}; then
    redis_create_user ${app} ${admin} && \
    redis_set_requirepass ${admin} ${admin}
  fi
)}

function redis_cli_clean_docker() {(
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_info ${fname} "Use ${BOLD}docker_rm_redis${RESET} instead."
)}

#function docker_exec_init_redis() {
#  docker_service_check_redis
#  local exec="$(ctx_docker_redis && docker_exec)"
#  local set_requirepass="$(ctx_redis_app && redis_set_requirepass)"
#  if [ -n "${set_requirepass}" ]; then dt_exec ${fname} "${exec} ${set_requirepass}"; fi
#  local create_user="$(ctx_redis_app && redis_create_user)"
#  dt_exec ${fname} "${exec} ${create_user}"
#}
