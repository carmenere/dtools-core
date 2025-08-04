. ${DT_VARS}/cargo/apps/defaults.sh

BUILD_AS="package"
PACKAGE="tetrix"
#CLIPPY_LINTS="-Dwarnings"
MANIFEST_DIR="${DT_PROJECT}"

cg_add_bin "tetrix-api"
add_env DATABASE_URL "$(. "${DT_VARS}/conns/pg/migrator.sh" && . "${ACCOUNT}" && echo "$(pg_conn_url)")"
add_env BUILD_VERSION "$(git_build_version)"