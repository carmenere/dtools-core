clickhouse_connurl() {
  local vars=(CLICKHOUSE_DB CLICKHOUSE_HOST CLICKHOUSE_PASSWORD CLICKHOUSE_PORT CLICKHOUSE_USER)
  echo "${vars[@]}"
}

ctx_conn_clickhouse() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  if [ "${PROFILE_CLICKHOUSE}" = "docker" ]; then
    load_vars ctx_docker_clickhouse CLICKHOUSE_HOST CLICKHOUSE_PORT || return $?
  else
    load_vars ctx_service_clickhouse CLICKHOUSE_HOST CLICKHOUSE_PORT || return $?
  fi
  ctx_epilog ${fname}
}

ctx_conn_admin_clickhouse() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var CLICKHOUSE_USER "dt_admin"
  var CLICKHOUSE_PASSWORD "1234567890"
  var CLICKHOUSE_DB "default"
  ctx_conn_clickhouse && \
  ctx_epilog ${fname}
}

ctx_conn_app_clickhouse() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var CLICKHOUSE_USER "example_app"
  var CLICKHOUSE_PASSWORD "1234567890"
  var CLICKHOUSE_DB "example"
  ctx_conn_clickhouse && \
  ctx_epilog ${fname}
}

clickhouse_conn_admin() { open_ctx ctx_conn_admin_clickhouse && clickhouse_conn && close_ctx; }
clickhouse_conn_app() { open_ctx ctx_conn_app_clickhouse && clickhouse_conn && close_ctx; }

clickhouse_init() {
  if [ "${PROFILE_CLICKHOUSE}" = "docker" ]; then docker_check_clickhouse || return $?; else service_check_clickhouse || return $?; fi && \
  _clickhouse_init ctx_conn_admin_clickhouse ctx_conn_app_clickhouse
}

clickhouse_clean() {
  if [ "${PROFILE_CLICKHOUSE}" = "docker" ]; then docker_check_clickhouse || return $?; else service_check_clickhouse || return $?; fi && \
  _clickhouse_clean ctx_conn_admin_clickhouse ctx_conn_app_clickhouse
}