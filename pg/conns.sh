psql_conn_url=(PGHOST PGPORT PGUSER PGDATABASE PGPASSWORD)

function conn_pg_admin() {
  for var in ${psql_conn_url[@]}; do local ${var} 1>/dev/null 2>1; done
  local ctx=$0
  if [ "$(os_name)" = "macos" ]; then
    PGUSER="${USER}"
  else
    PGUSER="postgres"
  fi
  PGPASSWORD="postgres"
  PGDATABASE="postgres"
  dt_set_ctx ${ctx} ${psql_conn_url[@]}
}

function conn_pg_app() {
  for var in ${psql_conn_url[@]}; do local ${var} 1>/dev/null 2>1; done
  local ctx=$0
  PGUSER="example_app"
  PGPASSWORD="1234567890"
  PGDATABASE="example"
  dt_set_ctx ${ctx} ${psql_conn_url[@]}
}

function conn_pg_migrator() {
  for var in ${psql_conn_url[@]}; do local ${var} 1>/dev/null 2>1; done
  local ctx=$0
  PGUSER="example_migrator"
  PGPASSWORD="1234567890"
  PGDATABASE="example"
  dt_set_ctx ${ctx} ${psql_conn_url[@]}
}

function conn_docker_pg_admin() {
  dt_load_ctx conn_pg_admin ${psql_conn_url[@]}
  local ctx=$0
  PGUSER="postgres"
  dt_set_ctx ${ctx} ${psql_conn_url[@]}
}

function conn_docker_pg_app() {
  dt_load_ctx conn_pg_admin ${psql_conn_url[@]}
  local ctx=$0
  dt_set_ctx ${ctx} ${psql_conn_url[@]}
}

function conn_docker_pg_migrator() {
  dt_load_ctx conn_pg_admin ${psql_conn_url[@]}
  local ctx=$0
  dt_set_ctx ${ctx} ${psql_conn_url[@]}
}
