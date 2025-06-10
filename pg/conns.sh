function ctx_connurl_pg() {
  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  c=$1; if [ -z "${c}" ]; then c=${fname}; if dt_cached ${c}; then return 0; fi; fi;
  pg_docker=ctx_docker_pg
  pg_host=ctx_service_pg
  ${pg_docker} &&  ${pg_host} || return $?
  var $c PSQL "$(gvar ${pg_host} PSQL)"
  if [ "$(get_profile pg_docker)" = "pg_docker" ]; then
    var $c PGHOST "$(gvar ${pg_docker} PGHOST)"
    var $c PGPORT "$(gvar ${pg_docker} PGPORT)"
  else
    var $c PGHOST "$(gvar ${pg_host} PGHOST)"
    var $c PGPORT "$(gvar ${pg_host} PGPORT)"
  fi
  if [ "$(os_name)" = "macos" ]; then
    var $c PGUSER "${USER}"
  else
    var $c PGUSER "postgres"
  fi
  var $c PGPASSWORD "postgres"
  var $c PGDATABASE "postgres"
  dt_cache ${c}
}

function ctx_connurl_pg_migrator() {
  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  c=$1; if [ -z "${c}" ]; then c=${fname}; if dt_cached ${c}; then return 0; fi; fi;
  var $c PGUSER "example_migrator"
  var $c PGPASSWORD "1234567890"
  var $c PGDATABASE "example"
  ctx_connurl_pg ${c} && dt_cache ${c}
}

function ctx_connurl_pg_app() {
  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  c=$1; if [ -z "${c}" ]; then c=${fname}; if dt_cached ${c}; then return 0; fi; fi;
  var $c PGUSER "example_app"
  var $c PGPASSWORD "1234567890"
  ctx_connurl_pg_migrator ${c} && dt_cache ${c}
}