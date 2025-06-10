function ctx_docker_pg() {
  local fname c MAJOR MINOR BASE_IMAGE PGPORT
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  c=$1; if [ -z "${c}" ]; then c=${fname}; if dt_cached ${c}; then return 0; fi; fi;
  load_vars ctx_service_pg "MAJOR MINOR"
  if [ "$(uname -m)" = "arm64" ]; then
    BASE_IMAGE="arm64v8/postgres:${MAJOR}.${MINOR}-alpine3.21"
  else
    BASE_IMAGE="postgres:${MAJOR}.${MINOR}-alpine3.21"
  fi
  PGPORT=5411
  var $c PGPORT ${PGPORT}
  var $c PUBLISH "${PGPORT}:5432/tcp"
  var $c CTX "."
  var $c IMAGE "${BASE_IMAGE}"
  var $c BASE_IMAGE "${BASE_IMAGE}"
#  IMAGE   "pg:${DEFAULT_TAG}"
#  BUILDER ${BUILDER_IMAGE}
#  BUILD_VERSION "$(git_build_version)"
  var $c BACKGROUND "y"
  var $c CONTAINER "postgres"
  var $c RESTART "always"
  var $c CHECK_CMD "sh -c 'pg_isready 1>/dev/null 2>&1'"
  var $c docker_run_envs "POSTGRES_DB POSTGRES_PASSWORD POSTGRES_USER"
  var $c hook_pre_docker_run pre_docker_run_pg
  ctx_service_pg ${c} && \
  ctx_docker_image ${c} && \
  ctx_docker_container ${c} && \
  ctx_docker_network ${c}
  dt_cache ${c}
}

dt_register "ctx_docker_pg" "pg" "$(docker_methods)"

#function ctx_docker_pg() {
#  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
#  c=$1; if [ -z "${c}" ]; then c=${fname}; if dt_cached ${c}; then return 0; fi; fi;
#  root_docker_pg ${c} && dt_cache ${c}
#}

function pre_docker_run_pg() {
  local PGPASSWORD PGDATABASE PGUSER POSTGRES_PASSWORD POSTGRES_DB POSTGRES_USER
  load_vars ctx_connurl_pg "PGPASSWORD PGDATABASE PGUSER"
  POSTGRES_PASSWORD=${PGPASSWORD}
  POSTGRES_DB=${PGDATABASE}
  POSTGRES_USER=${PGUSER}
}
