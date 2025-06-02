function pg_db_postgres() {
  PGDATABASE="postgres"
}

function pg_db_example() {
  PGDATABASE="example"
}

function pg_user_admin() {
  PGPASSWORD="postgres"
  if [ "$(os_name)" = "macos" ]; then
    PGUSER="${USER}"
  else
    PGUSER=postgres
  fi
}

function pg_user_docker_admin() {
  PGPASSWORD="postgres"
  PGUSER=postgres
}

function pg_user_app() {
  PGPASSWORD="12345"
  PGUSER="example_app"
}

function pg_user_migrator() {
  PGPASSWORD="12345"
  PGUSER="example_migrator"
}

function ctx_conn_pg_admin() {
  ctx_service_pg && \
  pg_db_postgres && \
  pg_user_admin
}

function ctx_conn_pg_migrator() {
  ctx_service_pg && \
  pg_db_example && \
  pg_user_migrator
}

function ctx_conn_pg_app() {
  ctx_service_pg && \
  pg_db_example && \
  pg_user_app
}

function ctx_conn_docker_pg_admin() {
  ctx_docker_pg && \
  pg_db_postgres && \
  pg_user_docker_admin
}

function ctx_conn_docker_pg_migrator() {
  ctx_docker_pg && \
  pg_db_example && \
  pg_user_migrator
}

function ctx_conn_docker_pg_app() {
  ctx_docker_pg && \
  pg_db_example && \
  pg_user_app
}
