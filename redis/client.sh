function redis_exec() {
  local fname conn query_ctx=$1 conn_ctx=$2 query=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "query_ctx conn_ctx query" || return $?
  dt_debug ${fname} "query_ctx=${query_ctx}"
  query=$(${query_ctx} && ${query}) || return $?
  dt_debug ${fname} "conn_ctx=${conn_ctx}"
  conn="$(${conn_ctx} && cmd_echo redis_conn)" || return $?
  cmd_exec "${conn} ${query}"
}

function redis_conn() {
  local cmd fname=$(fname "${FUNCNAME[0]}" "$0")
  cmd=("redis-cli -e -u")
  cmd+=("redis://${REDIS_USER}:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}")
  cmd_exec "${cmd[@]}"
}

function redis_set_requirepass() {
  redis_exec $1 $2 redis_ql_set_requirepass
}

function redis_check_user() { redis_exec $1 $2 redis_ql_check_user; }
function redis_create_user() { redis_exec $1 $2 redis_ql_create_user; }
function redis_drop_user() { redis_exec $1 $2 redis_ql_drop_user; }

function redis_config_rewrite() {
  local conn_ctx=$1
  cmd_exec "$(${conn_ctx} && cmd_echo redis_conn) CONFIG REWRITE"
}

function redis_flushall() {
  local conn_ctx=$1
  cmd_exec "$(${conn_ctx} && cmd_echo redis_conn) FLUSHALL"
}

function redis_cli_init() {(
  if [ "${PROFILE_REDIS}" = "docker" ]; then docker_service_check_redis; else service_check_redis; fi || return $?
  admin=ctx_conn_admin_redis
  app=ctx_conn_app_redis
  ctx_conn_redis || return $?
  if ! redis_check_user ${app} ${admin}; then
    redis_create_user ${app} ${admin} && \
    redis_set_requirepass ${admin} ${admin} && \
    redis_config_rewrite ${admin}
  fi
)}

function redis_cli_clean() {(
  if [ "${PROFILE_REDIS}" = "docker" ]; then docker_service_check_redis; else service_check_redis; fi || return $?
  admin=ctx_conn_admin_redis
  app=ctx_conn_app_redis
  ctx_conn_redis || return $?
  if redis_check_user ${app} ${admin}; then
    redis_drop_user ${app} ${admin} && \
    redis_flushall ${admin} && \
    redis_config_rewrite ${admin}
  fi
)}

function redis_cli_conn_admin() {( ctx_conn_redis && ctx_conn_admin_redis && redis_conn; )}
function redis_cli_conn_app() {( ctx_conn_redis && ctx_conn_app_redis && redis_conn; )}

#function docker_exec_init_redis() {
#  docker_service_check_redis
#  local exec="$(ctx_docker_redis && docker_exec)"
#  local set_requirepass="$(ctx_conn_app_redis && redis_set_requirepass)"
#  if [ -n "${set_requirepass}" ]; then cmd_exec "${exec} ${set_requirepass}"; fi
#  local create_user="$(ctx_conn_app_redis && redis_create_user)"
#  cmd_exec "${exec} ${create_user}"
#}