. ${DT_VARS}/docker_images/defaults.sh
. <(
  . ${DT_VARS}/services/redis_7.2.sh
  echo "MAJOR=${MAJOR}"
  echo "MINOR=${MINOR}"
  echo "PATCH=${PATCH}"
)
IMAGE="$(docker_arm64v8)redis:${MAJOR}.${MINOR}.${PATCH}-alpine3.19"

LOCALS=${DT_LOCAL_VARS}/docker_images/redis_7.2.sh
source_locals ${LOCALS}