pg_docker_vars=(${docker_vars[@]} ${pg_vars[@]})

function ctx_docker_pg() {
  local ctx=$0; dt_skip_if_initialized || return $?
  eval "vars_${ctx}=pg_docker_vars"
  dt_load_vars -c ctx_service_pg && \
  dt_load_vars -c ctx_docker_image && \
  dt_load_vars -c ctx_docker_container && \
  dt_load_vars -c ctx_docker_network || return $?

  if [ "$(uname -m)" = "arm64" ]; then
    BASE_IMAGE="arm64v8/postgres:${MAJOR}.${MINOR}-alpine3.21"
  else
    BASE_IMAGE="postgres:${MAJOR}.${MINOR}-alpine3.21"
  fi
  PGPORT=5411
  PUBLISH=("${PGPORT}:5432/tcp")
  CTX="."
  IMAGE=${BASE_IMAGE}
#  IMAGE = "pg:${DEFAULT_TAG}"
#  BUILDER=${BUILDER_IMAGE}
#  BUILD_VERSION="$(git_build_version)"
  BACKGROUND="y"
  CONTAINER="postgres"
  RESTART="always"
  CHECK_CMD="sh -c 'pg_isready 1>/dev/null 2>&1'"
  docker_run_envs=(POSTGRES_DB POSTGRES_PASSWORD POSTGRES_USER)
  hook_pre_docker_run=pre_docker_run_pg
  dt_set_ctx -c ${ctx} -d
}

function pre_docker_run_pg() {
  dt_load_vars -c ctx_docker_pg_admin -m 'PGPASSWORD=>POSTGRES_PASSWORD' -m 'PGDATABASE=>POSTGRES_DB' -m 'PGUSER=>POSTGRES_USER'

}

dt_register "ctx_docker_pg" "pg" "${docker_methods[@]}"

