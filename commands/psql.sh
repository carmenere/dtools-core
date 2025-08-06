_psql_sudo() {
  if [ "$(service_mode)" = "docker" ]; then
    echo ""
    return 0
  fi
  if [ -n "$(dt_sudo)" ]; then
    echo "$(dt_sudo) -u ${user}"
  else
    echo ""
  fi
}

_psql_host() { if [ -n "${host}" ]; then echo "PGHOST=${host}"; fi; }
_psql_port() { if [ -n "${port_psql}" ]; then echo "PGPORT=${port_psql}"; fi; }
_psql_user() { if [ -n "${user}" ]; then echo "PGUSER=${user}"; fi; }
_psql_password() { if [ -n "${password}" ]; then echo "PGPASSWORD=${password}"; fi }
_psql_db() { if [ -n "${database}" ]; then echo "PGDATABASE=${database}"; fi }

_pg_connurl() { echo "$(_psql_host) $(_psql_port) $(_psql_db) $(_psql_user) $(_psql_password)"; }
_pg_local_connurl() { echo "$(_psql_port) $(_psql_db) $(_psql_user)"; }

psql_conn() {(
  set -eu
  . "${DT_VARS}/conns/pg/$1.sh"
  . "${ACCOUNT}"
  echo "$(_pg_connurl)"
  ${TERMINAL} ${SERVICE_ID} $(_pg_connurl) ${PSQL}
)}

psql_local_conn() {(
  set -eu
  . "${DT_VARS}/conns/pg/$1.sh"
  . "${ACCOUNT}"
  echo "$(_pg_connurl)"
  ${TERMINAL} ${SERVICE_ID} $(_psql_sudo) $(_pg_local_connurl) ${PSQL}
)}

m4_psql_query() {
  (set -eu; . "${DT_VARS}/conns/accounts/pg/$2.sh" &&
    M4_TVARS=${DT_M4}/pg/sql/vars.m4
    M4_IN="${DT_M4}/pg/sql/$1"
    M4_OUT=
    declare -A envs
    ENVS=()
    add_env M4_USER ${user}
    add_env M4_PASSWORD ${password}
    add_env M4_DATABASE ${database}
    _m4
  )
}

_psql_gexec() {
  local query=$(echo "$(m4_psql_query $1 $2)")
  local query=$(escape_dollar "$(escape_quote "${query}")")
  . "${DT_VARS}/conns/pg/$2.sh" && . "${CONN}"
  ${EXEC} ${SERVICE_ID} "echo $'${query}' '\gexec' | $(_pg_connurl) ${PSQL}"
}

_psql_gexec_local() {
  local query=$(echo "$(m4_psql_query $1 $2)")
  local query=$(escape_dollar "$(escape_quote "${query}")")
  . "${DT_VARS}/conns/pg/$2.sh" && . "${CONN}"
  ${EXEC} ${SERVICE_ID} "echo $'${query}' '\gexec' | $(_psql_sudo) $(_pg_local_connurl) ${PSQL}"
}

psql_alter_role_password() {( set -eu; _psql_gexec_local "alter_role_password.sql" $1 )}
psql_drop_role_password() {( set -eu; _psql_gexec "drop_role_password.sql" $1 )}
psql_create_user() {( set -eu; _psql_gexec "create_user.sql" $1 )}
psql_drop_user() {( set -eu; _psql_gexec "drop_user.sql" $1 )}
psql_create_db() {( set -eu; _psql_gexec "create_db.sql" $1 )}
psql_drop_db() {( set -eu; _psql_gexec "drop_db.sql" $1 )}

psql_grant_user() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  local query=$(echo "$(m4_psql_query $(. "${ACCOUNT}" && echo ${GRANT}) $1)")
  local query=$(escape_dollar "$(escape_quote "${query}")")
  . "${CONN}" && database=$(. "${ACCOUNT}" && echo ${database})
  ${EXEC} ${SERVICE_ID} "echo $'${query}' '\gexec' | $(_pg_connurl) ${PSQL}"
)}

psql_revoke_user() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  _psql_gexec $(. "${ACCOUNT}" && echo ${REVOKE}) $1
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