_rmq_sudo() {
  if [ "${MODE}" = "docker" ]; then
    echo ""
  else
    local s="$(dt_sudo)"
    if [ -n "${s}" ]; then
      echo "${s} "
    else
      echo ""
    fi
  fi
}

_rabbitmqadmin_connurl() {
  host="--host ${host}"
  port_client="--port ${port_client}"
  user="--username ${user}"
  password="--password ${password}"
}

_rabbitmqctl() { echo "$(_rmq_sudo)rabbitmqctl"; }

rabbitmq_conn() {(
  set -eu
  local cmd=
  . "${DT_VARS}/conns/$1/$2.sh"
  shift 2
  local conn=$(_rabbitmqadmin_connurl)
  if [ -n "$*" ]; then
    cmd="$*"
  fi
  ${TERMINAL} ${SERVICE} "$(_rabbitmqctl) ${cmd}"
)}

rabbitmq_check_user() {(
  set -eu; . "${DT_VARS}/conns/$1/$2.sh"
  ${EXEC} ${SERVICE} "$(_rabbitmqctl) --quiet list_users | sed -n '1d;p' | cut -d$'\t' -f1 | grep -m 1 '^${user}$'"
)}

rabbitmq_create_user() {(
  set -eu; . "${DT_VARS}/conns/$1/$2.sh"
  echo "$(_rabbitmqctl) add_user ${user} ${password} EXEC=${EXEC}"
  ${EXEC} ${SERVICE} "$(_rabbitmqctl) add_user ${user} ${password}"
)}

rabbitmq_drop_user() {(
  set -eu; . "${DT_VARS}/conns/$1/$2.sh"
  ${EXEC} ${SERVICE} "$(_rabbitmqctl) delete_user ${user}"
)}

rmq_set_user_tags() {(
  set -eu; . "${DT_VARS}/conns/$1/$2.sh"
  set -eu; ${EXEC} ${SERVICE} "$(_rabbitmqctl) set_user_tags ${user} administrator"
)}

rmq_set_permissions() {(
  set -eu; . "${DT_VARS}/conns/$1/$2.sh"
  set -eu; ${EXEC} ${SERVICE} "$(_rabbitmqctl) set_permissions -p / ${user} '.*' '.*' '.*'"
)}

rabbitmq_flush() {(
  set -eu; . "${DT_VARS}/conns/$1/$2.sh"
  queues=($(echo "${QUEUES}"))
  exchanges=($(echo "${EXCHANGES}"))
  if [ -z "${AUX_CONN}" ]; then
    dt_error "rabbitmq_flush" "The variable ${BOLD}AUX_CONN${RESET} doesn't set for account $2"
    return 99
  fi
  . "${AUX_CONN}"
  conn="$(_rabbitmqadmin_connurl)"
  for queue in ${queues[@]}; do
    ${EXEC} ${SERVICE} "rabbitmqadmin ${conn} delete queue name='${queue}' || true"
  done
  for exchange in ${exchanges[@]}; do
    ${EXEC} ${SERVICE} "rabbitmqadmin ${conn} delete exchange name='${exchange}' || true"
  done
)}

rabbitmq_check() {(
  rabbitmq_conn $1 $2 $'status' 1\>/dev/null
)}

function rabbitmq_init() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  service_check rabbitmq_check $1 ${ADMIN}
  if ! rabbitmq_check_user $1 ${APP}; then
    rabbitmq_create_user $1 ${APP}
    rmq_set_user_tags $1 ${APP}
    rmq_set_permissions $1 ${APP}
  fi
)}

function rabbitmq_clean() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  service_check rabbitmq_check $1 ${ADMIN}
  if rabbitmq_check_user $1 ${APP}; then
    rabbitmq_drop_user $1 ${APP}
    rabbitmq_flush $1 ${APP}
  fi
)}

function rabbitmq_reinit() {(
  rabbitmq_clean $1 && rabbitmq_init $1
)}

##################################################### AUTOCOMPLETE #####################################################
cmd_family_rabbitmq() {
  local methods=()
  methods+=(rabbitmq_conn)
  methods+=(rabbitmq_check_user)
  methods+=(rabbitmq_create_user)
  methods+=(rabbitmq_drop_user)
  methods+=(rmq_set_user_tags)
  methods+=(rmq_set_permissions)
  methods+=(rabbitmq_flush)
  methods+=(rabbitmq_check)
  echo "${methods[@]}"
}

cmd_family_rabbitmq_batch() {
  local methods=()
  methods+=(rabbitmq_init)
  methods+=(rabbitmq_clean)
  methods+=(rabbitmq_reinit)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_rabbitmq"
autocomplete_reg_family "cmd_family_rabbitmq_batch"

autocomplete_cmd_family_rabbitmq() {
  local cur prev
  local options
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case ${COMP_CWORD} in
    1)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_rabbitmq_services]}" -- ${cur}))
      ;;
    2)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_rabbitmq]}" -- ${cur}))
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}