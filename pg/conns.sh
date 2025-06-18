pg_connurl() {
  local vars=(PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER)
  echo "${vars}"
}

ctx_conn_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  if [ "${PROFILE_PG}" = "docker" ]; then
    load_vars ctx_docker_pg PGHOST PGPORT PSQL
  else
    load_vars ctx_service_pg PGHOST PGPORT PSQL
  fi
  ctx_epilog ${fname}
}

ctx_conn_admin_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  if [ "$(os_name)" = "macos" ] && [ "${PROFILE_PG}" = "host" ]; then
    var PGUSER "${USER}"
  else
    var PGUSER "postgres"
  fi
  var PGPASSWORD "postgres"
  var PGDATABASE "postgres"
  ctx_conn_pg && \
  ctx_epilog ${fname}
}

ctx_conn_migrator_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var PGUSER "example_migrator"
  var PGPASSWORD "1234567890"
  var PGDATABASE "example"
  ctx_conn_pg && \
  ctx_epilog ${fname}
}

ctx_conn_app_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var PGUSER "example_app"
  var PGPASSWORD "1234567890"
  ctx_conn_migrator_pg && \
  ctx_epilog ${fname}
}
