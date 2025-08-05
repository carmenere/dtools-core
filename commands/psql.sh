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
_pg_local_connurl() { echo "$(_psql_port) $(_psql_db) $(_psql_user) $@"; }

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

_m4_psql_query() {
  (set -eu; . "${ACCOUNT}" &&
    M4_TVARS=${DT_M4}/pg/sql/vars.m4
    M4_IN=$1
    export M4_USER=${user}
    export M4_PASSWORD=${password}
    export M4_PASSWORD=${password}
    export M4_DATABASE=${database}
    _m4
  )
}

_psql_gexec() {
  local M4_OUT=${DT_M4_OUT}/$(basename $1)
  _m4_psql_query $1
  local query=$(echo "$(cat ${M4_OUT})")
  local query="$(escape_dollar "$(escape_quote "${query}")")"
  . "${CONN}"
  ${EXEC} ${SERVICE_ID} "echo $'${query}' '\gexec' | $(_pg_connurl) ${PSQL}"
}

_psql_gexec_local() {
  local M4_OUT=${DT_M4_OUT}/$(basename $1)
  _m4_psql_query $1
  local query=$(echo "$(cat ${M4_OUT})")
  local query="$(escape_dollar "$(escape_quote "${query}")")"
  . "${CONN}"
  ${EXEC} ${SERVICE_ID} "echo $'${query}' '\gexec' | $(_psql_sudo) $(_pg_local_connurl) ${PSQL}"
}

psql_alter_role_password() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  _psql_gexec_local "${DT_M4}/pg/sql/alter_role_password.sql"
)}
psql_drop_role_password() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  _psql_gexec_local "${DT_M4}/pg/sql/drop_role_password.sql"
)}
psql_create_user() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  _psql_gexec "${DT_M4}/pg/sql/create_user.sql"
)}
psql_drop_user() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  _psql_gexec "${DT_M4}/pg/sql/drop_user.sql"
)}
psql_create_db() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  _psql_gexec "${DT_M4}/pg/sql/create_db.sql"
)}
psql_drop_db() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  _psql_gexec "${DT_M4}/pg/sql/drop_db.sql"
)}
psql_grant_user() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  local GRANT=$(. "${ACCOUNT}" && echo ${GRANT})
  local M4_OUT=${DT_M4_OUT}/$(basename ${GRANT})
  _m4_psql_query ${GRANT}
  local query=$(echo "$(cat ${M4_OUT})")
  local query="$(escape_dollar "$(escape_quote "${query}")")"
  . "${CONN}"
  database=$(. "${ACCOUNT}" && echo ${database})
  ${EXEC} ${SERVICE_ID} "echo $'${query}' '\gexec' | $(_pg_connurl) ${PSQL}"
)}
psql_revoke_user() {(
  set -eu; . "${DT_VARS}/conns/pg/$1.sh"
  _psql_gexec $(. "${ACCOUNT}" && echo ${REVOKE})
)}

psql_init() {(
  set -eu; . "${DT_VARS}/conns/$1/psql_batch.sh"
  psql_create_db ${MIGRATOR}
  psql_create_user ${MIGRATOR}
  psql_grant_user ${MIGRATOR}
  psql_create_user ${APP}
  psql_grant_user ${APP}
)}
psql_clean() {(
  set -eu; . "${DT_VARS}/conns/$1/psql_batch.sh"
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