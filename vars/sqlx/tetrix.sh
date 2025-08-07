. ${DT_VARS}/sqlx/defaults.sh

APP_ID="tetrix-api"
SCHEMAS="${DT_PROJECT}/migrations/schemas"
TMP_SCHEMAS="${DT_ARTEFACTS}/schemas"

add_env DATABASE_URL "$(. "${DT_VARS}/conns/pg/migrator.sh" && . "${ACCOUNT}" && echo "$(pg_conn_url)")"



dt_debug "sdfdsf" "dsfdsf"