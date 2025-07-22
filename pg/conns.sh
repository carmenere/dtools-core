select_service_pg() { if [ "$(pg_mode)" = "docker" ]; then echo "ctx_pg_docker"; else echo "ctx_pg_host"; fi; }

function ctx_conn_admin_pg() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var PGUSER $(pg_superuser) && \
  var PGPASSWORD "postgres" && \
  var PGDATABASE "postgres" && \
  var CONN ctx_conn_admin_pg && \
  $(select_service_pg) ${caller} && \
  cache_ctx
}

function ctx_conn_migrator_pg() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var PGUSER "example_migrator" && \
  var PGPASSWORD "1234567890" && \
  var PGDATABASE "example" && \
  var GRANT sql_pg_grant_user_migrator && \
  var REVOKE sql_pg_revoke_user_migrator && \
  var CONN ctx_conn_admin_pg && \
  var GRANT_CONN ctx_conn_admin_pg && \
  ctx_conn_admin_pg ${caller} && \
  cache_ctx
}

function ctx_conn_app_pg() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var PGUSER "example_app" && \
  var PGPASSWORD "1234567890" && \
  var PGDATABASE "example" && \
  var GRANT sql_pg_grant_user_app && \
  var REVOKE sql_pg_revoke_user_app && \
  var CONN ctx_conn_admin_pg && \
  var GRANT_CONN ctx_conn_migrator_pg && \
  ctx_conn_admin_pg ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_conn_admin_pg:admin:psql_methods)
DT_BINDINGS+=(ctx_conn_migrator_pg:migrator:psql_methods)
DT_BINDINGS+=(ctx_conn_app_pg:app:psql_methods)

function psql_init() {
  switch_ctx $(select_service_pg) && $(CHECK) && \
  _psql_init ctx_conn_admin_pg ctx_conn_migrator_pg ctx_conn_app_pg
}

function psql_clean() {
  switch_ctx $(select_service_pg) && $(CHECK) && \
  _psql_clean ctx_conn_admin_pg ctx_conn_migrator_pg ctx_conn_app_pg
}
