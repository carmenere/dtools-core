function ctx_docker_pg() {
  ctx_docker_network && ctx_docker_service || return $?
  CHECK_CMD="sh -c 'pg_isready 1>/dev/null 2>&1'"
  CONTAINER="postgres"
  CTX="."
  PGPORT=5411
  PGHOST="localhost"

  BASE_IMAGE="$(docker_arm64v8)postgres:17.5-alpine3.21"
  IMAGE=${BASE_IMAGE}
}

register "ctx_docker_pg" "pg" "$(docker_methods)"

docker_run_pg() {
  ctx_docker_pg || return $?
  RUN_ENVS=(POSTGRES_PASSWORD POSTGRES_DB POSTGRES_USER)
  load_vars ctx_connurl_pg "PGPASSWORD PGDATABASE PGUSER" || return $?
  POSTGRES_PASSWORD="${PGPASSWORD}"
  POSTGRES_DB="${PGDATABASE}"
  POSTGRES_USER="${PGUSER}"
  PUBLISH=("${PGPORT}:5432/tcp")
  docker_run
}
