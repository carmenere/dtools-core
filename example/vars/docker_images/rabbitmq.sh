. ${DT_VARS}/docker_images/defaults.sh
. <(
  . ${DT_VARS}/services/rabbitmq_3.8.sh
  echo "MAJOR=${MAJOR}"
  echo "MINOR=${MINOR}"
  echo "PATCH=${PATCH}"
)
IMAGE="$(docker_arm64v8)rabbitmq:${MAJOR}.${MINOR}.${PATCH}-rc.1-management-alpine"

LOCALS=${DT_LOCAL_VARS}/docker_images/rabbitmq_3.8.sh
source_locals ${LOCALS}