ctx_conn_admin_pg() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); dt_debug ${ctx} ">>>>> ctx=${ctx}, caller=?????"; set_caller $1; if is_cached; then return 0; fi
  var PGUSER $(pg_superuser)
  var PGPASSWORD "postgres"
  var PGDATABASE "postgres"
  $(select_service_pg) ${caller} && \
  cache_ctx
}

ctx_conn_migrator_pg() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); dt_debug ${ctx} ">>>>> ctx=${ctx}, caller=?????"; set_caller $1; if is_cached; then return 0; fi
  var PGUSER "example_migrator"
  var PGPASSWORD "1234567890"
  var PGDATABASE "example"
  $(select_service_pg) ${caller} && \
  cache_ctx
}

ctx_conn_app_pg() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); dt_debug ${ctx} ">>>>> ctx=${ctx}, caller=?????"; set_caller $1; if is_cached; then return 0; fi
  var PGUSER "example_app"
  var PGPASSWORD "1234567890"
  var PGDATABASE "example"
  $(select_service_pg) ${caller} && \
  cache_ctx
}

function psql_init() {
  switch_ctx $(select_service_pg) && \
  $(get_method "${DT_CTX}" $(select_service_check "${PROFILE_PG}")) && \
  _psql_init "ctx_conn_admin_pg" "ctx_conn_migrator_pg" "ctx_conn_app_pg" $(select_exec "${PROFILE_PG}")
}

function psql_clean() {
  switch_ctx $(select_service_pg) && \
  $(get_method "${DT_CTX}" $(select_service_check "${PROFILE_PG}")) && \
  _psql_clean "ctx_conn_admin_pg" "ctx_conn_migrator_pg" "ctx_conn_app_pg" $(select_exec "${PROFILE_PG}")
}

function psql_conn_admin() {
  switch_ctx $(select_service_pg) && \
  _psql_conn ctx_conn_admin_pg $(select_exec "${PROFILE_PG}_conn_sh") "$@"
}
function psql_conn_app() {
  switch_ctx $(select_service_pg) && \
  _psql_conn ctx_conn_app_pg $(select_exec "${PROFILE_PG}_conn_sh") "$@"
}
function psql_conn_migrator() {
  switch_ctx $(select_service_pg) && \
  _psql_conn ctx_conn_migrator_pg $(select_exec "${PROFILE_PG}_conn_sh") "$@"
}
