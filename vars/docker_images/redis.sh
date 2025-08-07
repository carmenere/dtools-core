. ${DT_VARS}/docker_images/defaults.sh
. <(
  . ${DT_VARS}/services/redis.sh
  echo "MAJOR=${MAJOR}"
  echo "MINOR=${MINOR}"
  echo "PATCH=${PATCH}"
)
IMAGE="$(docker_arm64v8)redis:${MAJOR}.${MINOR}.${PATCH}-alpine3.19"
