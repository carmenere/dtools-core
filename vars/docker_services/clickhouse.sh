. ${DT_VARS}/docker_services/defaults.sh

# Docker service and OS service must share the same SERVICE, because it is used in conns
SERVICE="clickhouse"
# By default, SERVICE is a name of container
CONTAINER="${SERVICE}"

. <(set -ue; . ${DT_VARS}/docker_images/clickhouse.sh
  echo "IMAGE=${IMAGE}"
)

. <(set -ue; . ${DT_VARS}/docker_bridges/example.sh
  echo BRIDGE="${BRIDGE}"
)

HOST_CONN="localhost"
PORT_CONN_HTTP=4444

HOST_BIND="localhost"
PORT_BIND=9000
PORT_BIND_HTTP=8123

CLIENT="clickhouse-client"

add_publish "${PORT_CONN_HTTP}:${PORT_BIND_HTTP}/tcp"

. <(set -ue; . ${DT_VARS}/conns/clickhouse/_admin.sh
  echo "add_run_env CLICKHOUSE_DB ${database}"
  echo "add_run_env CLICKHOUSE_PASSWORD ${password}"
  echo "add_run_env CLICKHOUSE_USER ${user}"
)

add_run_env CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT 1

