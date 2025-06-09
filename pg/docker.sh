function docker_pg_vars() {
  local c=$1
  var $c MAJOR "$(gvar ctx_service_pg MAJOR)"
  var $c MINOR "$(gvar ctx_service_pg MINOR)"
  if [ "$(uname -m)" = "arm64" ]; then
    var $c BASE_IMAGE "arm64v8/postgres:$(gvar $c MAJOR).$(gvar $c MINOR)-alpine3.21"
  else
    var $c BASE_IMAGE "postgres:$(gvar $c MAJOR).$(gvar $c MINOR)-alpine3.21"
  fi
  var $c PGPORT 5411
  var $c PUBLISH "${PGPORT}:5432/tcp"
  var $c CTX "."
  var $c IMAGE ${BASE_IMAGE}
#  IMAGE   "pg:${DEFAULT_TAG}"
#  BUILDER ${BUILDER_IMAGE}
#  BUILD_VERSION "$(git_build_version)"
  var $c BACKGROUND "y"
  var $c CONTAINER "postgres"
  var $c RESTART "always"
  var $c CHECK_CMD "sh -c 'pg_isready 1>/dev/null 2>&1'"
  var $c docker_run_envs "POSTGRES_DB POSTGRES_PASSWORD POSTGRES_USER"
  var $c hook_pre_docker_run pre_docker_run_pg
  docker_image_vars ${c}
#  ctx_service_pg && \
#  ctx_docker_image && \
#  ctx_docker_container && \
#  ctx_docker_network || return $?
}

  function ctx_docker_pg() {
  local ctx=$(dt_fname "${FUNCNAME[0]}" "$0")
  drop_ctx ${ctx} && \
  docker_pg_vars ${ctx}
}

dt_register "ctx_docker_pg" "pg" "${docker_methods[@]}"

function pre_docker_run_pg() {
  ctx_docker_pg_admin || return $?
  POSTGRES_PASSWORD=${PGPASSWORD}
  POSTGRES_DB=${PGDATABASE}
  POSTGRES_USER=${PGUSER}
}
