. ${DT_VARS}/docker_services/defaults.sh

SERVICE="postgres"

. <(set -ue; . ${DT_VARS}/docker_images/pg.sh
  echo "IMAGE=${IMAGE}"
)

. <(set -ue; . ${DT_VARS}/docker_bridges/example.sh
  echo BRIDGE="${BRIDGE}"
)

HOST_CONN=2222
PORT_CONN=2222
HOST_BIND="localhost"
PORT_BIND=5432

PSQL=psql

add_publish "${PORT_CONN}:${PORT_BIND}/tcp"

. <(set -ue; . ${DT_VARS}/conns/accounts/pg/admin.sh
  echo "add_run_env POSTGRES_DB \"${database}\""
  echo "add_run_env POSTGRES_PASSWORD \"${password}\""
)
echo err=$?
add_run_env POSTGRES_USER "${PG_SUPERUSER}"