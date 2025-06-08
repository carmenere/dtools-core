function ctx_pg_admin() {
  if [ "$(os_name)" = "macos" ]; then
    PGUSER="${USER}"
  else
    PGUSER="postgres"
  fi
  PGPASSWORD="postgres"
  PGDATABASE="postgres"
}

function ctx_pg_app() {
  PGUSER="example_app"
  PGPASSWORD="1234567890"
  PGDATABASE="example"
}

function ctx_pg_migrator() {
  PGUSER="example_migrator"
  PGPASSWORD="1234567890"
  PGDATABASE="example"
}

function ctx_docker_pg_admin() {
  ctx_pg_admin || return $?
  PGUSER="postgres"
}
