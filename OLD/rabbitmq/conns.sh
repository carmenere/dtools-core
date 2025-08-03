select_service_rmq() { if [ "$(rmq_mode)" = "docker" ]; then echo "ctx_rmq_docker"; else echo "ctx_rmq_host"; fi; }

function ctx_conn_admin_rmq() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var RMQ_USER "guest" && \
  var RMQ_PASSWORD "guest" && \
  var CONN ctx_conn_admin_rmq && \
  $(select_service_rmq) ${caller} && \
  cache_ctx
}

function ctx_conn_app_rmq() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var RMQ_USER "example_app" && \
  var RMQ_PASSWORD 12345 && \
  var CONN ctx_conn_admin_rmq && \
  $(select_service_rmq) ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_conn_admin_rmq:admin:rmq_methods)
DT_BINDINGS+=(ctx_conn_app_rmq:app:rmq_methods)

function rmq_init() {
  switch_ctx $(select_service_rmq) && $(CHECK) && \
  _rmq_init ctx_conn_app_rmq
}

function rmq_clean() {
  switch_ctx $(select_service_rmq) && $(CHECK) && \
  _rmq_clean ctx_conn_app_rmq
}
