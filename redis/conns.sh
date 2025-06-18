ctx_conn_redis() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  if [ "${PROFILE_REDIS}" = "docker" ]; then
    load_vars ctx_docker_redis REDIS_HOST REDIS_PORT || return $?
  else
    load_vars ctx_service_redis REDIS_HOST REDIS_PORT || return $?
  fi
  ctx_epilog ${fname}
}

function ctx_conn_admin_redis() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var REDIS_USER "default"
  var REDIS_PASSWORD "1234567890"
  var REDIS_DB 0
  ctx_conn_redis && \
  ctx_epilog ${fname}
}

function ctx_conn_app_redis() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var REDIS_USER "example_app"
  var REDIS_PASSWORD "1234567890"
  var REDIS_DB 0
  ctx_conn_redis && \
  ctx_epilog ${fname}
}

function redis_cli_init() {
  if [ "${PROFILE_REDIS}" = "docker" ]; then docker_check_redis || return $?; else service_check_redis || return $?; fi || return $?
  admin=ctx_conn_admin_redis
  app=ctx_conn_app_redis
  if ! redis_check_user ${app} ${admin}; then
    redis_create_user ${app} ${admin} && \
    redis_set_requirepass ${admin} ${admin} && \
    redis_config_rewrite ${admin}
  fi
}

function redis_cli_clean() {
  if [ "${PROFILE_REDIS}" = "docker" ]; then docker_check_redis || return $?; else service_check_redis || return $?; fi || return $?
  admin=ctx_conn_admin_redis
  app=ctx_conn_app_redis
  if redis_check_user ${app} ${admin}; then
    redis_drop_user ${app} ${admin} && \
    redis_flushall ${admin} && \
    redis_config_rewrite ${admin}
  fi
}

function redis_cli_conn_admin() { ctx_conn_admin_redis && redis_conn; }
function redis_cli_conn_app() { ctx_conn_app_redis && redis_conn; }

#function docker_exec_init_redis() {
#  docker_check_redis
#  local exec="$(ctx_docker_redis && docker_exec)"
#  local set_requirepass="$(ctx_conn_app_redis && redis_set_requirepass)"
#  if [ -n "${set_requirepass}" ]; then cmd_exec "${exec} ${set_requirepass}"; fi
#  local create_user="$(ctx_conn_app_redis && redis_create_user)"
#  cmd_exec "${exec} ${create_user}"
#}