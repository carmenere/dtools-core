function ctx_pg_docker() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var BASE_IMAGE "$(docker_arm64v8)postgres:17.5-alpine3.21" && \
  var SERVICE_CHECK "pg_isready 1>/dev/null 2>&1" && \
  var CONTAINER "postgres" && \
  var PUB_PGPORT 2222 && \
  var PGPORT 5432 && \
  var PSQL psql && \
  var RUN_ENVS "POSTGRES_PASSWORD POSTGRES_DB POSTGRES_USER" && \
  var PUBLISH "$(PUB_PGPORT):$(PGPORT)/tcp" && \
  ctx_docker_network ${caller} && ctx_docker_service ${caller} && ctx_pg_host ${caller} && \
  cache_ctx
}

docker_run_pg() {
  switch_ctx ctx_pg_docker && \
  load_vars ctx_conn_admin_pg PGPASSWORD PGDATABASE PGUSER && \
  var POSTGRES_PASSWORD "$(PGPASSWORD)" && \
  var POSTGRES_DB "$(PGDATABASE)" && \
  var POSTGRES_USER "$(PGUSER)" && \
  docker_run
}

c=ctx_pg_docker; add_deps "${c}" "ctx_conn_admin_pg"
DT_BINDINGS+=(${c}:pg:docker_methods:"docker_run_pg")
