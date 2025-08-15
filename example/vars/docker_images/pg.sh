. ${DT_VARS}/docker_images/defaults.sh
. <(
  . ${DT_VARS}/services/pg_17.sh
  echo "MAJOR=${MAJOR}"
  echo "MINOR=${MINOR}"
)
IMAGE="$(docker_arm64v8)postgres:${MAJOR}.${MINOR}-alpine3.21"

LOCALS=${DT_LOCAL_VARS}/docker_images/pg_17.sh
source_locals ${LOCALS}