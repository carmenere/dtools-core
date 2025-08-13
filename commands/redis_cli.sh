_redis_connurl() { echo "redis://${user}:${password}@${host}:${port_client}/${database}"; }
_redis_create_user() { echo "ACL SETUSER ${user} \>${password} on allkeys allcommands"; }
_redis_drop_user() { echo "ACL DELUSER ${user}"; }
_redis_check_user() { echo "ACL DRYRUN ${user} PING"; }
_redis_set_requirepass() { echo "config set requirepass \"\""; }
_redis_config_rewrite() { echo "CONFIG REWRITE"; }
_redis_flushall() { echo "FLUSHALL"; }

_redis_aux_exec() {
  . "${DT_VARS}/conns/$2/$3.sh"
  local query=$(echo "$($1)")
  if [ -z "${AUX_CONN}" ]; then
    dt_error "_redis_exec" "The variable ${BOLD}AUX_CONN${RESET} doesn't set for account $3"
    return 99
  fi
  . "${AUX_CONN}"
  connurl=$(_redis_connurl)
  ${EXEC} ${SERVICE} ${CLIENT} -e -u ${connurl} ${query}
}

_redis_exec() {
  . "${DT_VARS}/conns/$2/$3.sh"
  local query=$(echo "$($1)")
  connurl=$(_redis_connurl)
  ${EXEC} ${SERVICE} ${CLIENT} -e -u ${connurl} ${query}
}

redis_conn() {(
  set -eu
  . "${DT_VARS}/conns/$1/$2.sh"
  shift 2
  connurl=$(_redis_connurl)
  if [ -n "$*" ]; then
    cmd="-c '$*'"
  fi
  ${TERMINAL} ${SERVICE} ${CLIENT} -e -u ${connurl} ${cmd}
)}

redis_check_user() {( set -eu; _redis_aux_exec _redis_check_user $1 $2; )}
redis_create_user() {( set -eu; _redis_aux_exec _redis_create_user $1 $2; )}
redis_drop_user() {( set -eu; _redis_aux_exec _redis_drop_user $1 $2; )}
redis_config_rewrite() {( set -eu; _redis_exec _redis_config_rewrite $1 $2; )}
redis_flushall() {( set -eu; _redis_exec _redis_flushall $1 $2; )}
redis_set_requirepass() {( set -eu; _redis_exec _redis_set_requirepass $1 $2; )}

redis_check() {(
  redis_conn $1 $2 $'ping'
)}

redis_init() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  service_check redis_check $1 ${ADMIN}
  if ! redis_check_user $1 ${APP}; then
    redis_create_user $1 ${APP}
    redis_set_requirepass $1 ${ADMIN}
    if [ "${MODE}" = "docker" ]; then return; fi
    redis_config_rewrite $1 ${ADMIN}
  fi
)}

redis_clean() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  service_check redis_check $1 ${ADMIN}
  if redis_check_user $1 ${APP}; then
    redis_drop_user $1 ${APP}
    redis_flushall $1 ${ADMIN}
    if [ "${MODE}" = "docker" ]; then return; fi
    redis_config_rewrite $1 ${ADMIN}
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
  methods+=(redis_check)
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

autocomplete_cmd_family_redis() {
  local cur prev
  local options
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case ${COMP_CWORD} in
    1)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_redis_services]}" -- ${cur}))
      ;;
    2)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_redis]}" -- ${cur}))
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}