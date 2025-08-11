pg_dumpX() {(
  set -eu; . "${DT_VARS}/conns/$1/$2.sh"
  local DB=${database}
  PG_DUMP="${DT_LOGS}/db-${DB}.dump"
  [ -d $(dirname ${PG_DUMP}) ] || mkdir -p $(dirname ${PG_DUMP})
  if [ -z "${AUX_CONN}" ]; then
    dt_error "pg_dump" "The variable ${BOLD}AUX_CONN${RESET} doesn't set for account $2"
    return 99
  fi
  . "${AUX_CONN}"
  database=${DB}
  connurl=$(_pg_connurl)
  exec_cmd ${connurl} pg_dump --format custom --no-owner --no-privileges --file=${PG_DUMP}
  echo PG_DUMP=${PG_DUMP}
)}

pg_restoreX() {(
  set -eu; . "${DT_VARS}/conns/$1/$2.sh"
  local DB=${database}
  PG_DUMP="${DT_LOGS}/db-${DB}.dump"
  if [ -z "${AUX_CONN}" ]; then
    dt_error "pg_restore" "The variable ${BOLD}AUX_CONN${RESET} doesn't set for account $2"
    return 99
  fi
  . "${AUX_CONN}"
  database=${DB}
  connurl=$(_pg_connurl)
  exec_cmd ${connurl} pg_restore --no-owner -d ${DB} --single-transaction "${PG_DUMP}"
  echo "Ok"
)}


##################################################### AUTOCOMPLETE #####################################################
function cmd_family_dump_restore() {
  local methods=()
  methods+=(pg_dumpX)
  methods+=(pg_restoreX)
  echo "${methods[@]}"
}
