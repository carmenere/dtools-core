. ${DT_VARS}/docker_images/defaults.sh
. <(
  . ${DT_VARS}/services/clickhouse_23.sh
  echo "MAJOR=${MAJOR}"
  echo "MINOR=${MINOR}"
)
IMAGE="clickhouse/clickhouse-server:${MAJOR}.${MINOR}-alpine"

LOCALS=${DT_LOCAL_VARS}/docker_images/clickhouse_23.sh
source_locals ${LOCALS}