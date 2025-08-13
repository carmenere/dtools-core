declare -A envs
ENVS=()

. <(. "${DT_VARS}/cargo/package/tetrix.sh"
  echo "BINS_DIR=\"${BINS_DIR}\""
)

. <(. "${DT_VARS}/conns/pg/app.sh"
  echo "add_env TTX_PGPORT ${port_app}"
  echo "add_env TTX_PGHOST ${host}"
  echo "add_env TTX_PGDATABASE ${database}"
  echo "add_env TTX_PGPASSWORD ${password}"
  echo "add_env TTX_PGUSER ${user}"
)

APP="tetrix-api"
OPTS=
BINARY="${BINS_DIR}/${APP}"
PKILL_PATTERN="${BINARY}"
LOG_FILE="${DT_LOGS}/${APP}.logs"

LOCALS=${DT_LOCAL_VARS}/apps/${APP}.sh
source_locals ${LOCALS}
