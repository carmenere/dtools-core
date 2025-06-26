select_service_redis() { if [ "$(redis_mode)" = "docker" ]; then echo "ctx_redis_docker"; else echo "ctx_redis_host"; fi; }

function ctx_conn_admin_redis() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var REDIS_USER "default" && \
  var REDIS_PASSWORD "1234567890" && \
  var REDIS_DB 0 && \
  var CONN ctx_conn_admin_redis && \
  $(select_service_redis) ${caller} && \
  cache_ctx
}

function ctx_conn_app_redis() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var REDIS_USER "example_app" && \
  var REDIS_PASSWORD "1234567890" && \
  var REDIS_DB 0 && \
  var CONN ctx_conn_admin_redis && \
  $(select_service_redis) ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_conn_admin_redis:admin:redis_methods)
DT_BINDINGS+=(ctx_conn_app_redis:app:redis_methods)

function redis_init() {
  switch_ctx $(select_service_redis) && $(CHECK) && \
  _redis_init ctx_conn_admin_redis ctx_conn_app_redis
}

function redis_clean() {
  switch_ctx $(select_service_redis) && $(CHECK) && \
  _redis_clean ctx_conn_admin_redis ctx_conn_app_redis
}