function ctx_docker_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local dt_ctx; ctx_prolog ${fname} || return $?; if is_cached ${fname}; then return 0; fi
  var BASE_IMAGE "$(docker_arm64v8)postgres:17.5-alpine3.21"
  var SERVICE_CHECK "pg_isready 1>/dev/null 2>&1"
  var CONTAINER "postgres"
  var PUB_PGPORT 2222
  var PGPORT 5432
  var PSQL psql
  ctx_docker_network && ctx_docker_service && ctx_service_pg && \
  ctx_epilog ${fname}
}

docker_run_pg() {
  switch_ctx ctx_docker_pg || return $?
  load_vars ctx_conn_admin_pg PGPASSWORD PGDATABASE PGUSER || return $?
  var -r RUN_ENVS "POSTGRES_PASSWORD POSTGRES_DB POSTGRES_USER"
  var -r PUBLISH "$(PUB_PGPORT):$(PGPORT)/tcp"
  var POSTGRES_PASSWORD "$(PGPASSWORD)"
  var POSTGRES_DB "$(PGDATABASE)"
  var POSTGRES_USER "$(PGUSER)"
  docker_run
}

DT_BINDINGS+=(ctx_docker_pg:pg:docker_methods:"docker_run_pg")
