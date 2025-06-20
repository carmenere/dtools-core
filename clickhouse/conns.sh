clickhouse_connurl() {
  local vars=(CLICKHOUSE_DB CLICKHOUSE_HOST CLICKHOUSE_PASSWORD CLICKHOUSE_PORT CLICKHOUSE_USER)
  echo "${vars[@]}"
}

ctx_conn_admin_clickhouse() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi
  var CLICKHOUSE_USER "dt_admin"
  var CLICKHOUSE_PASSWORD "1234567890"
  var CLICKHOUSE_DB "default"
  $(select_service ${PROFILE_CLICKHOUSE} "clickhouse") && \
  ctx_epilog ${fname}
}

ctx_conn_app_clickhouse() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi
  var CLICKHOUSE_USER "example_app"
  var CLICKHOUSE_PASSWORD "1234567890"
  var CLICKHOUSE_DB "example"
  $(select_service ${PROFILE_CLICKHOUSE} "clickhouse") && \
  ctx_epilog ${fname}
}

clickhouse_conn_admin() { _clickhouse_conn ctx_conn_admin_clickhouse "$@"; }
clickhouse_conn_app() { _clickhouse_conn ctx_conn_app_clickhouse "$@"; }

clickhouse_init() {
  $(select_checker ${PROFILE_CLICKHOUSE} "clickhouse") && \
  _clickhouse_init "ctx_conn_admin_clickhouse" "ctx_conn_app_clickhouse"
}

clickhouse_clean() {
  $(select_checker ${PROFILE_CLICKHOUSE} "clickhouse") && \
  _clickhouse_clean "ctx_conn_admin_clickhouse" "ctx_conn_app_clickhouse"
}
