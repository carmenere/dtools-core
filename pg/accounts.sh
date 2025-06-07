pg_account=( PGUSER PGDATABASE PGPASSWORD )
pg_account_vars=( PGUSER PGDATABASE PGPASSWORD ${dt_vars[@]})

function ctx_pg_admin() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=("${pg_account_vars}")
  if [ "$(os_name)" = "macos" ]; then
    PGUSER="${USER}"
  else
    PGUSER="postgres"
  fi
  PGPASSWORD="postgres"
  PGDATABASE="postgres"
  dt_set_ctx -c ${ctx}
}

function ctx_pg_app() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=("${pg_account_vars}")
  PGUSER="example_app"
  PGPASSWORD="1234567890"
  PGDATABASE="example"
  dt_set_ctx -c ${ctx}
}

function ctx_pg_migrator() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=("${pg_account_vars}")
  PGUSER="example_migrator"
  PGPASSWORD="1234567890"
  PGDATABASE="example"
  dt_set_ctx -c ${ctx}
}

function ctx_docker_pg_admin() {
  local ctx=$0; dt_skip_if_initialized && return 0
  dt_load_vars -c ctx_pg_admin || return $?
  PGUSER="postgres"
  dt_set_ctx -c ${ctx}
}
