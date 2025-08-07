. ${DT_VARS}/docker_services/defaults.sh

# Docker service and OS service must share the same SERVICE, because it is used in conns
SERVICE="redis"
# By default, SERVICE is a name of container
CONTAINER="${SERVICE}"

. <(set -ue; . ${DT_VARS}/docker_images/redis.sh
  echo "IMAGE=${IMAGE}"
)

. <(set -ue; . ${DT_VARS}/docker_bridges/example.sh
  echo BRIDGE="${BRIDGE}"
)

HOST_CONN="localhost"
PORT_CONN=6380
HOST_BIND="localhost"
PORT_BIND=6379

CLIENT=redis-cli

add_publish "${PORT_CONN}:${PORT_BIND}/tcp"
