pg_connurl() {
  local vars=(PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER)
  echo "${vars}"
}

ctx_socket_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "${PROFILE_PG}" = "docker" ]; then
    ctx_docker_pg || return $?
  else
    ctx_service_pg || return $?
  fi
  # call to load PSQL when profile docker
  ctx_service_pg || return $?
}

ctx_account_admin_pg() {
  if [ "$(os_name)" = "macos" ] && [ "${PROFILE_PG}" = "host" ]; then
    var PGUSER "${USER}"
  else
    var PGUSER "postgres"
  fi
  var PGPASSWORD "postgres"
  var PGDATABASE "postgres"
}

ctx_account_migrator_pg() {
  var PGUSER "example_migrator"
  var PGPASSWORD "1234567890"
  var PGDATABASE "example"
}

ctx_account_app_pg() {
  var PGUSER "example_app"
  var PGPASSWORD "1234567890"
  ctx_account_migrator_pg || return $?
}
