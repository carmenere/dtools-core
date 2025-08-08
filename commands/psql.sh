_psql_sudo() {
  if [ "${MODE}" = "docker" ]; then
    echo ""
    return 0
  fi
  if [ -n "$(dt_sudo)" ]; then
    echo "$(dt_sudo) -u ${user}"
  else
    echo ""
  fi
}

_pg_connurl() {
  declare -A envs && ENVS=()
  add_env PGHOST ${host} && add_env PGPORT ${port_client} && add_env PGDATABASE ${database} && \
  add_env PGUSER ${user} && add_env PGPASSWORD ${password} && \
  echo "$(inline_envs)"
}
_pg_local_connurl() {
  declare -A envs && ENVS=()
  add_env PGPORT ${port_client} && add_env PGUSER ${user} && add_env PGDATABASE ${database} && \
  echo "$(inline_envs)"
}

psql_conn() {(
  set -eu
  . "${DT_VARS}/conns/pg/$1.sh"
  connurl=$(_pg_connurl)
  ${TERMINAL} ${SERVICE} ${connurl} ${CLIENT}
)}

psql_local_conn() {(
  set -eu
  . "${DT_VARS}/conns/pg/$1.sh"
  connurl=$(_pg_local_connurl)
  sudo=$(_psql_sudo)
  ${TERMINAL} ${SERVICE} ${sudo} ${connurl} ${CLIENT}
)}

m4_psql_query() {(
  set -eu; . "${DT_VARS}/conns/pg/$2.sh"
  _m4_psql_query $1
)}

_m4_psql_query() {
  M4_TVARS=${DT_M4}/pg/sql/vars.m4
  M4_IN="${DT_M4}/pg/sql/$1"
  M4_OUT=
  declare -A envs
  ENVS=()
  add_env M4_USER ${user}
  add_env M4_PASSWORD ${password}
  add_env M4_DATABASE ${database}
  _m4
}

_psql_aux_gexec() {
  . "${DT_VARS}/conns/pg/$2.sh"
  local query=$(echo "$(_m4_psql_query $1)")
  local query=$(escape_dollar "$(escape_quote "${query}")")
  if [ -z "${AUX_CONN}" ]; then
    dt_error "_psql_aux_gexec" "The variable ${BOLD}AUX_CONN${RESET} doesn't set for account $2"
    return 99
  fi
  . "${AUX_CONN}"
  connurl=$(_pg_connurl)
  ${EXEC} ${SERVICE} "echo $'${query}' '\gexec' | ${connurl} ${CLIENT}"
}

_psql_gexec_local() {
  . "${DT_VARS}/conns/pg/$2.sh"
  local query=$(echo "$(_m4_psql_query $1)")
  local query=$(escape_dollar "$(escape_quote "${query}")")
  # admin has no AUX_CONN, and we connect to db behalf admin itself
  if [ -n "${AUX_CONN}" ]; then . "${AUX_CONN}"; fi
  connurl=$(_pg_local_connurl)
  sudo=$(_psql_sudo)
  ${EXEC} ${SERVICE} "echo $'${query}' '\gexec' | ${sudo} ${connurl} ${CLIENT}"
}

psql_alter_role_password() {( set -eu; _psql_gexec_local "alter_role_password.sql" $1 )}
psql_drop_role_password() {( set -eu; _psql_aux_gexec "drop_role_password.sql" $1 )}
psql_create_user() {( set -eu; _psql_aux_gexec "create_user.sql" $1 )}
psql_drop_user() {( set -eu; _psql_aux_gexec "drop_user.sql" $1 )}
psql_create_db() {( set -eu; _psql_aux_gexec "create_db.sql" $1 )}
psql_drop_db() {( set -eu; _psql_aux_gexec "drop_db.sql" $1 )}

psql_grant_user() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  local query=$(echo "$(m4_psql_query "${GRANT}" $1)")
  local query=$(escape_dollar "$(escape_quote "${query}")")
  local _database=${database}
  . "${AUX_CONN}"
  # during connection we must use db (${_database}) from actual account (conns/pg/$1.sh), not from AUX_CONN
  local database=${_database}
  ${EXEC} ${SERVICE} "echo $'${query}' '\gexec' | $(_pg_connurl) ${CLIENT}"
)}

psql_revoke_user() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  _psql_aux_gexec "${REVOKE}" $1
)}

psql_init() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  psql_create_db ${MIGRATOR}
  psql_create_user ${MIGRATOR}
  psql_grant_user ${MIGRATOR}
  psql_create_user ${APP}
  psql_grant_user ${APP}
)}

psql_clean() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  psql_drop_db ${MIGRATOR}
  psql_drop_user ${MIGRATOR}
  psql_drop_user ${APP}
)}

psql_reinit() {
  psql_clean $1 && psql_init $1
}

##################################################### AUTOCOMPLETE #####################################################
cmd_family_psql() {
  local methods=()
  methods+=(psql_alter_role_password)
  methods+=(psql_conn)
  methods+=(psql_local_conn)
  methods+=(psql_create_db)
  methods+=(psql_create_user)
  methods+=(psql_drop_db)
  methods+=(psql_drop_role_password)
  methods+=(psql_drop_user)
  methods+=(psql_grant_user)
  methods+=(psql_revoke_user)
  echo "${methods[@]}"
}

cmd_family_psql_batch() {
  local methods=()
  methods+=(psql_init)
  methods+=(psql_clean)
  methods+=(psql_reinit)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_psql"
autocomplete_reg_family "cmd_family_psql_batch"

##################################################### AUTOCOMPLETE #####################################################
cmd_family_m4_psql_query() {
  local methods=()
  methods+=(m4_psql_query)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_m4_psql_query"

autocomplete_cmd_family_m4_psql_query() {
  local cur prev
  local options
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case ${COMP_CWORD} in
    1)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_m4_psql_query]}" -- ${cur}))
      ;;
    2)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_psql]}" -- ${cur}))
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}