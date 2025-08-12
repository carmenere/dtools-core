_redis_connurl() { echo "redis://${user}:${password}@${host}:${port_client}/${database}"; }
_redis_create_user() { echo "ACL SETUSER ${user} \>${password} on allkeys allcommands"; }
_redis_drop_user() { echo "ACL DELUSER ${user}"; }
_redis_check_user() { echo "ACL DRYRUN ${user} PING"; }
_redis_set_requirepass() { echo "config set requirepass \"\""; }
_redis_config_rewrite() { echo "CONFIG REWRITE"; }
_redis_flushall() { echo "FLUSHALL"; }

_redis_aux_exec() {
  . "${DT_VARS}/conns/redis/$2.sh"
  local query=$(echo "$($1)")
  if [ -z "${AUX_CONN}" ]; then
    dt_error "_redis_exec" "The variable ${BOLD}AUX_CONN${RESET} doesn't set for account $2"
    return 99
  fi
  . "${AUX_CONN}"
  connurl=$(_redis_connurl)
  ${EXEC} ${SERVICE} ${CLIENT} -e -u ${connurl} ${query}
}

_redis_exec() {
  . "${DT_VARS}/conns/redis/$2.sh"
  local query=$(echo "$($1)")
  connurl=$(_redis_connurl)
  ${EXEC} ${SERVICE} ${CLIENT} -e -u ${connurl} ${query}
}

redis_conn() {(
  set -eu
  . "${DT_VARS}/conns/redis/$1.sh"
  connurl=$(_redis_connurl)
  ${TERMINAL} ${SERVICE} ${CLIENT} -e -u ${connurl}
)}

redis_check_user() {( set -eu; _redis_aux_exec _redis_check_user $1; )}
redis_create_user() {( set -eu; _redis_aux_exec _redis_create_user $1; )}
redis_drop_user() {( set -eu; _redis_aux_exec _redis_drop_user $1; )}
redis_config_rewrite() {( set -eu; _redis_exec _redis_config_rewrite $1; )}
redis_flushall() {( set -eu; _redis_exec _redis_flushall $1; )}
redis_set_requirepass() {( set -eu; _redis_exec _redis_set_requirepass $1; )}

redis_init() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  if ! redis_check_user ${APP}; then
    redis_create_user ${APP}
    redis_set_requirepass ${ADMIN}
    if [ "${MODE}" = "docker" ]; then return; fi
    redis_config_rewrite ${ADMIN}
  fi
)}

redis_clean() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  if redis_check_user ${APP}; then
    redis_drop_user ${APP}
    redis_flushall ${ADMIN}
    if [ "${MODE}" = "docker" ]; then return; fi
    redis_config_rewrite ${ADMIN}
  fi
)}

redis_reinit() {
  redis_clean $1 && redis_init $1
}

##################################################### AUTOCOMPLETE #####################################################
cmd_family_redis() {
  local methods=()
  methods+=(redis_check_user)
  methods+=(redis_config_rewrite)
  methods+=(redis_conn)
  methods+=(redis_create_user)
  methods+=(redis_drop_user)
  methods+=(redis_flushall)
  methods+=(redis_set_requirepass)
  echo "${methods[@]}"
}

cmd_family_redis_batch() {
  local methods=()
  methods+=(redis_init)
  methods+=(redis_clean)
  methods+=(redis_reinit)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_redis"
autocomplete_reg_family "cmd_family_redis_batch"
