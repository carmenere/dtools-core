_clickhouse_connurl() {
  host="--host ${host}"
  port_client="--port ${port_client}"
  database="--database ${database}"
  user="--user ${user}"
  password="--password ${password}"
  echo "${host} ${port_client} ${database} ${user} ${password}"
}

clickhouse_conn() {(
  set -eu
  local cmd=
  . "${DT_VARS}/conns/$1/$2.sh"
  shift 2
  connurl="$(_clickhouse_connurl)"
  if [ -n "$*" ]; then
    cmd="--query '$*'"
  fi
  ${TERMINAL} ${SERVICE} ${CLIENT} ${connurl} ${cmd}
)}

m4_clickhouse_query() {(
  set -eu; . "${DT_VARS}/conns/$2/$3.sh"
  _m4_clickhouse_query $1
)}

_m4_clickhouse_query() {
  M4_TVARS=${DT_M4}/clickhouse/ql/vars.m4
  M4_IN="${DT_M4}/clickhouse/ql/$1"
  M4_OUT=
  declare -A envs
  ENVS=()
  add_env M4_USER ${user}
  add_env M4_PASSWORD ${password}
  add_env M4_DATABASE ${database}
  _m4
}

_clickhouse_exec() {
  . "${DT_VARS}/conns/$2/$3.sh"
  local query=$(echo "$(_m4_clickhouse_query $1)")
  local query=$(escape_dollar "$(escape_quote "${query}")")
  if [ -z "${AUX_CONN}" ]; then
    dt_error "_clickhouse_exec" "The variable ${BOLD}AUX_CONN${RESET} doesn't set for account $3"
    return 99
  fi
  . "${AUX_CONN}"
  connurl="$(_clickhouse_connurl)"
  ${EXEC} ${SERVICE} ${CLIENT} "${connurl} --multiquery $'${query}'"
}

clickhouse_create_user() {( set -eu; _clickhouse_exec "create_user.sql" $1 $2 )}
clickhouse_drop_user() {( set -eu; _clickhouse_exec "drop_user.sql" $1 $2 )}
clickhouse_create_db() {( set -eu; _clickhouse_exec "create_db.sql" $1 $2 )}
clickhouse_drop_db() {( set -eu; _clickhouse_exec "drop_db.sql" $1 $2 )}

clickhouse_grant_user() {(
  set -eu; . "${DT_VARS}/conns/$1/$2.sh"
  _clickhouse_exec ${GRANT} $1 $2
)}

clickhouse_revoke_user() {(
  set -eu; . "${DT_VARS}/conns/$1/$2.sh"
  _clickhouse_exec ${REVOKE} $1 $2
)}

clickhouse_check() {(
  clickhouse_conn $1 $2 $'exit'
)}

clickhouse_init() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  service_check clickhouse_check $1 ${ADMIN}
  clickhouse_create_db $1 ${MIGRATOR}
  clickhouse_create_user $1 ${MIGRATOR}
  clickhouse_grant_user $1 ${MIGRATOR}
)}

clickhouse_clean() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  service_check clickhouse_check $1 ${ADMIN}
  clickhouse_drop_db $1 ${MIGRATOR}
  clickhouse_drop_user $1 ${MIGRATOR}
)}

clickhouse_reinit() {
  clickhouse_init $1 && clickhouse_clean $1
}

##################################################### AUTOCOMPLETE #####################################################
cmd_family_clickhouse() {
  local methods=()
  methods+=(clickhouse_conn)
  methods+=(clickhouse_create_db)
  methods+=(clickhouse_create_user)
  methods+=(clickhouse_drop_db)
  methods+=(clickhouse_drop_user)
  methods+=(clickhouse_grant_user)
  methods+=(clickhouse_revoke_user)
  methods+=(clickhouse_check)
  echo "${methods[@]}"
}

cmd_family_clickhouse_batch() {
  local methods=()
  methods+=(clickhouse_init)
  methods+=(clickhouse_clean)
  methods+=(clickhouse_reinit)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_clickhouse"
autocomplete_reg_family "cmd_family_clickhouse_batch"

autocomplete_cmd_family_clickhouse() {
  local cur prev
  local options
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case ${COMP_CWORD} in
    1)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_clickhouse_services]}" -- ${cur}))
      ;;
    2)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_clickhouse]}" -- ${cur}))
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}

##################################################### AUTOCOMPLETE #####################################################
cmd_family_m4_clickhouse_query() {
  local methods=()
  methods+=(m4_clickhouse_query)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_m4_clickhouse_query"

autocomplete_cmd_family_m4_clickhouse_query() {
  local cur prev
  local options
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case ${COMP_CWORD} in
    1)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_m4_clickhouse_query]}" -- ${cur}))
      ;;
    2)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_clickhouse_services]}" -- ${cur}))
      ;;
    3)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_clickhouse]}" -- ${cur}))
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}