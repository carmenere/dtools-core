. ${DT_VARS}/docker_images/defaults.sh
. <(
  . ${DT_VARS}/services/pg.sh
  echo "MAJOR=${MAJOR}"
  echo "MINOR=${MINOR}"
)
IMAGE="$(docker_arm64v8)postgres:${MAJOR}.${MINOR}-alpine3.21"
