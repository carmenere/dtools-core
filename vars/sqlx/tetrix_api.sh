. ${DT_VARS}/sqlx/defaults.sh

APP_ID="tetrix-api"
SCHEMAS="${DT_PROJECT}/migrations/schemas"
TMP_SCHEMAS="${DT_ARTEFACTS}/schemas"

. <(. "${DT_VARS}/cargo/apps/tetrix_package.sh"
  echo MANIFEST_DIR=${MANIFEST_DIR}
  echo "add_env BUILD_VERSION ${envs["BUILD_VERSION"]}"
  echo "add_env DATABASE_URL ${envs["DATABASE_URL"]}"
)


