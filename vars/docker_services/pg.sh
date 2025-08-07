. ${DT_VARS}/docker_services/defaults.sh

# Docker service and OS service must share the same SERVICE, because it is used in conns
SERVICE="pg"
# By default, SERVICE is a name of container
CONTAINER="${SERVICE}"

. <(set -ue; . ${DT_VARS}/docker_images/pg.sh
  echo "IMAGE=${IMAGE}"
)

. <(set -ue; . ${DT_VARS}/docker_bridges/example.sh
  echo BRIDGE="${BRIDGE}"
)

HOST_CONN="localhost"
PORT_CONN=2222
HOST_BIND="localhost"
PORT_BIND=5432

PSQL=psql

add_publish "${PORT_CONN}:${PORT_BIND}/tcp"

. <(set -ue; . ${DT_VARS}/conns/pg/_admin.sh
  echo "add_run_env POSTGRES_USER "${user}""
  echo "add_run_env POSTGRES_DB \"${database}\""
  echo "add_run_env POSTGRES_PASSWORD \"${password}\""
)
