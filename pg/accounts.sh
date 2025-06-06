pg_account=( PGUSER PGDATABASE PGPASSWORD )

function ctx_pg_admin() {
  local ctx=$0; dt_skip_if_initialized || return $?
  eval "vars_${ctx}=pg_account"
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
  local ctx=$0; dt_skip_if_initialized || return $?
  eval "vars_${ctx}=pg_account"
  PGUSER="example_app"
  PGPASSWORD="1234567890"
  PGDATABASE="example"
  dt_set_ctx -c ${ctx}
}

function ctx_pg_migrator() {
  local ctx=$0; dt_skip_if_initialized || return $?
  eval "vars_${ctx}=pg_account"
  PGUSER="example_migrator"
  PGPASSWORD="1234567890"
  PGDATABASE="example"
  dt_set_ctx -c ${ctx}
}

function ctx_docker_pg_admin() {
  local ctx=$0; dt_skip_if_initialized || return $?
  eval "vars_${ctx}=pg_account"
  dt_load_vars -c ctx_pg_admin
  PGUSER="postgres"
  dt_set_ctx -c ${ctx}
}
