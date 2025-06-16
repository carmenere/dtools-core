pg_connurl() {
  local vars=(PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER)
  echo "${vars}"
}

ctx_socket_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "$(get_profile pg_docker)" = "pg_docker" ]; then
    load_vars ctx_docker_pg "PGHOST PGPORT" || return $?
  else
    load_vars ctx_service_pg "PGHOST PGPORT" || return $?
  fi
  load_vars ctx_service_pg "PSQL" || return $?

  dt_debug ${fname} "PGPORT=${PGPORT}, PGHOST=${PGHOST}"
}

ctx_account_admin_pg() {
  if [ "$(os_name)" = "macos" ]; then
    PGUSER="${USER}"
  else
    PGUSER="postgres"
  fi
  PGPASSWORD="postgres"
  PGDATABASE="postgres"
}

ctx_account_migrator_pg() {
  PGUSER="example_migrator"
  PGPASSWORD="1234567890"
  PGDATABASE="example"
}

ctx_account_app_pg() {
  ctx_account_migrator_pg || return $?
  PGUSER="example_app"
  PGPASSWORD="1234567890"
}
