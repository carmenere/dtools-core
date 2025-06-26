select_service_clickhouse() {
  if [ "$(clickhouse_mode)" = "docker" ]; then echo "ctx_docker_clickhouse"; else echo "ctx_host_clickhouse"; fi
}

ctx_conn_admin_clickhouse() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var CLICKHOUSE_USER "dt_admin" && \
  var CLICKHOUSE_PASSWORD "1234567890" && \
  var CLICKHOUSE_DB "default" && \
  var CONN ctx_conn_admin_clickhouse && \
  $(select_service_clickhouse) ${caller} && \
  cache_ctx
}

ctx_conn_migrator_clickhouse() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var CLICKHOUSE_USER "example_migrator" && \
  var CLICKHOUSE_PASSWORD "1234567890" && \
  var CLICKHOUSE_DB "example" && \
  var GRANT sql_click_grant_user && \
  var REVOKE sql_click_revoke_user && \
  var CONN ctx_conn_admin_clickhouse && \
  $(select_service_clickhouse) ${caller} && \
  cache_ctx
}

ctx_conn_app_clickhouse() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var CLICKHOUSE_USER "example_app" && \
  var CLICKHOUSE_PASSWORD "1234567890" && \
  var CLICKHOUSE_DB "example" && \
  var GRANT sql_click_grant_user && \
  var REVOKE sql_click_revoke_user && \
  var CONN ctx_conn_admin_clickhouse && \
  $(select_service_clickhouse) ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_conn_admin_clickhouse:admin:clickhouse_methods)
DT_BINDINGS+=(ctx_conn_migrator_clickhouse:migrator:clickhouse_methods)
DT_BINDINGS+=(ctx_conn_app_clickhouse:app:clickhouse_methods)

function clickhouse_init() {
  switch_ctx $(select_service_clickhouse) && $(CHECK) && \
  _clickhouse_init ctx_conn_migrator_clickhouse ctx_conn_app_clickhouse
}

function clickhouse_clean() {
  switch_ctx $(select_service_clickhouse) && $(CHECK) && \
  _clickhouse_clean ctx_conn_migrator_clickhouse ctx_conn_app_clickhouse
}
