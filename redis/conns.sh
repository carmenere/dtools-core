function ctx_conn_admin_redis() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var REDIS_USER "default"
  var REDIS_PASSWORD "1234567890"
  var REDIS_DB 0
  $(select_service_redis) ${caller} && \
  cache_ctx
}

function ctx_conn_app_redis() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var REDIS_USER "example_app"
  var REDIS_PASSWORD "1234567890"
  var REDIS_DB 0
  $(select_service_redis) ${caller} && \
  cache_ctx
}

function redis_init() {
  switch_ctx $(select_service_redis) && \
  $(get_method "${DT_CTX}" $(select_service_check "${PROFILE_REDIS}")) && \
  _redis_init "ctx_conn_admin_redis" "ctx_conn_app_redis" $(select_exec "${PROFILE_REDIS}")
}

function redis_clean() {
  switch_ctx $(select_service_redis) && \
  $(get_method "${DT_CTX}" $(select_service_check "${PROFILE_REDIS}")) && \
  _redis_clean "ctx_conn_admin_redis" "ctx_conn_app_redis" $(select_exec "${PROFILE_REDIS}")
}

function redis_conn_admin() { _redis_conn ctx_conn_admin_redis $(select_exec "${PROFILE_REDIS}") "$@"; }
function redis_conn_app() { _redis_conn ctx_conn_app_redis $(select_exec "${PROFILE_REDIS}") "$@"; }
