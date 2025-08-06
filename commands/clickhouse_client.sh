_clickhouse_host() { if [ -n "${host}" ]; then echo "--host ${host}"; fi; }
_clickhouse_port() { if [ -n "${port_client}" ]; then echo "--port ${port_client}"; fi; }
_clickhouse_db() { if [ -n "${database}" ]; then echo "--database ${database}"; fi; }
_clickhouse_user() { if [ -n "${user}" ]; then echo "--user ${user}"; fi; }
_clickhouse_password() { if [ -n "${password}" ]; then echo "--password ${password}"; fi; }

_clickhouse_connurl() {
  echo "$(_clickhouse_host) $(_clickhouse_port) $(_clickhouse_db) $(_clickhouse_user) $(_clickhouse_password)"
}

clickhouse_conn() {(
  set -eu
  . "${DT_VARS}/conns/clickhouse/$1.sh"
  . "${ACCOUNT}"
  echo "$(_clickhouse_connurl)"
  ${TERMINAL} ${SERVICE_ID} ${CLIENT} $(_clickhouse_connurl) ${PSQL}
)}

m4_clickhouse_query() {
  (set -eu; . "${DT_VARS}/conns/accounts/clickhouse/$2.sh" &&
    M4_TVARS=${DT_M4}/clickhouse/ql/vars.m4
    M4_IN="${DT_M4}/clickhouse/ql/$1"
    M4_OUT=
    declare -A envs
    ENVS=()
    add_env M4_USER ${user}
    add_env M4_PASSWORD ${password}
    add_env M4_DATABASE ${database}
    _m4
  )
}

_clickhouse_exec() {
  local query=$(echo "$(m4_clickhouse_query $1 $2)")
  local query=$(escape_dollar "$(escape_quote "${query}")")
  . "${DT_VARS}/conns/clickhouse/$2.sh" && . "${CONN}"
  ${EXEC} ${SERVICE_ID} ${CLIENT} "$(_clickhouse_connurl) --multiquery $'${query}'"
}

clickhouse_create_user() {( set -eu; _clickhouse_exec "create_user.sql" $1 )}
clickhouse_drop_user() {( set -eu; _clickhouse_exec "drop_user.sql" $1 )}
clickhouse_create_db() {( set -eu; _clickhouse_exec "create_db.sql" $1 )}
clickhouse_drop_db() {( set -eu; _clickhouse_exec "drop_db.sql" $1 )}

clickhouse_grant_user() {(
  set -eu; . "${DT_VARS}/conns/clickhouse/$1.sh"
  local query=$(echo "$(m4_clickhouse_query $(. "${ACCOUNT}" && echo ${GRANT}) $1)")
  local query=$(escape_dollar "$(escape_quote "${query}")")
  . "${CONN}" && database=$(. "${ACCOUNT}" && echo ${database})
  ${EXEC} ${SERVICE_ID} ${CLIENT} "$(_clickhouse_connurl) --multiquery $'${query}'"
)}

clickhouse_revoke_user() {(
  set -eu; . "${DT_VARS}/conns/clickhouse/$1.sh"
  _clickhouse_exec $(. "${ACCOUNT}" && echo ${REVOKE}) $1
)}

clickhouse_init() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  clickhouse_create_db ${MIGRATOR}
  clickhouse_create_user ${MIGRATOR}
  clickhouse_grant_user ${MIGRATOR}
)}

clickhouse_clean() {(
  set -eu; . "${DT_VARS}/conns/$1/batch.sh"
  clickhouse_drop_db ${MIGRATOR}
  clickhouse_drop_user ${MIGRATOR}
)}

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
  echo "${methods[@]}"
}

cmd_family_clickhouse_batch() {
  local methods=()
  methods+=(clickhouse_init)
  methods+=(clickhouse_clean)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_clickhouse"
autocomplete_reg_family "cmd_family_clickhouse_batch"

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
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_clickhouse]}" -- ${cur}))
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}