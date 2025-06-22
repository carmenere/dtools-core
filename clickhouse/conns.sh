ctx_conn_admin_clickhouse() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var CLICKHOUSE_USER "dt_admin"
  var CLICKHOUSE_PASSWORD "1234567890"
  var CLICKHOUSE_DB "default"
  $(select_service_clickhouse) ${caller} && \
  cache_ctx
}

ctx_conn_app_clickhouse() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var CLICKHOUSE_USER "example_app"
  var CLICKHOUSE_PASSWORD "1234567890"
  var CLICKHOUSE_DB "example"
  $(select_service_clickhouse) ${caller} && \
  cache_ctx
}

function clickhouse_init() {
  switch_ctx $(select_service_clickhouse) && \
  $(get_method "${DT_CTX}" $(select_service_check "${PROFILE_CLICKHOUSE}")) && \
  _clickhouse_init "ctx_conn_admin_clickhouse" "ctx_conn_app_clickhouse" $(select_exec "${PROFILE_CLICKHOUSE}")
}

function clickhouse_clean() {
  switch_ctx $(select_service_clickhouse) && \
  $(get_method "${DT_CTX}" $(select_service_check "${PROFILE_CLICKHOUSE}")) && \
  _clickhouse_clean "ctx_conn_admin_clickhouse" "ctx_conn_app_clickhouse" $(select_exec "${PROFILE_CLICKHOUSE}")
}

function clickhouse_conn_admin() {
  switch_ctx $(select_service_clickhouse) && \
  _clickhouse_conn ctx_conn_admin_clickhouse $(select_exec "${PROFILE_CLICKHOUSE}_conn_sh") "$@"
}

function clickhouse_conn_app() {
  switch_ctx $(select_service_clickhouse) && \
  _clickhouse_conn ctx_conn_app_clickhouse $(select_exec "${PROFILE_CLICKHOUSE}_conn_sh") "$@"
}

