function ctx_conn_admin_pg() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var PGUSER $(pg_superuser $2) && \
  var PGPASSWORD "postgres" && \
  var PGDATABASE "postgres" && \
  $(select_ctx ctx_client pg_mode) ${caller} && \
  $(select_ctx ctx_pg pg_mode) ${caller} && \
  cache_ctx
}

function ctx_conn_migrator_pg() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var PGUSER "example_migrator" && \
  var PGPASSWORD "1234567890" && \
  var PGDATABASE "example" && \
  $(select_ctx ctx_client pg_mode) ${caller} && \
  $(select_ctx ctx_pg pg_mode) ${caller} && \
  cache_ctx
}

function ctx_conn_app_pg() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var PGUSER "example_app" && \
  var PGPASSWORD "1234567890" && \
  var PGDATABASE "example" && \
  $(select_ctx ctx_client pg_mode) ${caller} && \
  $(select_ctx ctx_pg pg_mode) ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_conn_admin_pg:admin:psql_methods)
DT_BINDINGS+=(ctx_conn_migrator_pg:migrator:psql_methods)
DT_BINDINGS+=(ctx_conn_app_pg:app:psql_methods)

function psql_init() {
  local admin=ctx_conn_admin_pg && \
  local migrator=ctx_conn_migrator_pg && \
  local app=ctx_conn_app_pg && \
  _psql_init
}

function psql_clean() {
  local admin=ctx_conn_admin_pg && \
  local migrator=ctx_conn_migrator_pg && \
  local app=ctx_conn_app_pg && \
  _psql_clean
}
