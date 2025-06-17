function ctx_docker_pg() {
  var CHECK_CMD "sh -c 'pg_isready 1>/dev/null 2>&1'"
  var CONTAINER "postgres"
  var CTX "."
  var PGPORT 2222
  var PGHOST "localhost"
  var BASE_IMAGE "$(docker_arm64v8)postgres:17.5-alpine3.21"
  var IMAGE ${BASE_IMAGE}
  ctx_docker_network && ctx_docker_service || return $?
}

DT_BINDINGS+=(ctx_docker_pg:pg:docker_methods)

docker_run_pg() {
  var RUN_ENVS "POSTGRES_PASSWORD POSTGRES_DB POSTGRES_USER"
  ctx_account_migrator_pg|| return $?
  var POSTGRES_PASSWORD "${PGPASSWORD}"
  var POSTGRES_DB "${PGDATABASE}"
  var POSTGRES_USER "${PGUSER}"
  var PUBLISH "${PGPORT}:5432/tcp"
  ctx_docker_pg || return $?
  docker_run
}
