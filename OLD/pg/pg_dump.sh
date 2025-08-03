
#function psql_dump_db() {
#  checks "$@" || return $?
#  local DB=$(. "${DTOOLS}/pg/accounts/$1.sh" && echo "${PGDATABASE}")
#  PG_DUMP="${DT_LOGS}/db-${DB}.dump"
#  [ -d $(dirname ${PG_DUMP}) ] || mkdir -p $(dirname ${PG_DUMP})
#  (
#    . "${DTOOLS}/pg/accounts/admin.sh"
#    pg_dump --format custom --no-owner --no-privileges --file=${PG_DUMP}
#    echo PG_DUMP=${PG_DUMP}
#  )
#}
#
#function psql_restore_db() {
#  checks "$@" || return $?
#  local DB=$(. "${DTOOLS}/pg/accounts/$1.sh" && echo "${PGDATABASE}")
#  PG_DUMP="${DT_LOGS}/db-${PGDATABASE}.dump"
#  (
#    . "${DTOOLS}/pg/accounts/admin.sh"
#    pg_restore --no-owner -d ${DB} --single-transaction "${PG_DUMP}"
#    echo "Ok"
#  )
#}