function ctx_docker_pg() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx_service_pg && \
  ctx_docker_image && \
  ctx_docker_container && \
  ctx_docker_network; exit_on_err ${fname} $? || return $?

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

  # hooks
  _hook_pre_docker_run=hooks_pre_docker_run_pg
  _docker_run_envs=(POSTGRES_DB POSTGRES_PASSWORD POSTGRES_USER)
}

function hooks_pre_docker_run_pg() {
  POSTGRES_DB=${PGDATABASE}
  POSTGRES_PASSWORD=${PGPASSWORD}
  POSTGRES_USER=${PGUSER}
}

dt_register ctx_conn_docker_pg_admin pg "${docker_methods[@]}"
