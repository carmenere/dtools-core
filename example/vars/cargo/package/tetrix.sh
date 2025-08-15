. ${DT_VARS}/cargo/package/defaults.sh

BINS+=(tetrix-api)

PACKAGE="tetrix"
#CLIPPY_LINTS+=("-Dwarnings")
MANIFEST_DIR="${DT_PROJECT}"

add_env DATABASE_URL "$(. "${DT_VARS}/conns/pg_17/migrator.sh" && echo "$(pg_conn_url)")"
add_env BUILD_VERSION "$(git_build_version)"
add_env RUSTUP_TOOLCHAIN "${RUSTUP_TOOLCHAIN}"

LOCALS=${DT_LOCAL_VARS}/cargo/package/tetrix.sh
source_locals ${LOCALS}