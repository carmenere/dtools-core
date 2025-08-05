. ${DT_VARS}/cargo/apps/defaults.sh

BINS+=("tetrix-api")
BUILD_AS="package"
PACKAGE="tetrix"
#CLIPPY_LINTS="-Dwarnings"
MANIFEST_DIR="${DT_PROJECT}"

add_env DATABASE_URL "$(. "${DT_VARS}/conns/pg/migrator.sh" && . "${ACCOUNT}" && echo "$(pg_conn_url)")"
add_env BUILD_VERSION "$(git_build_version)"
add_env RUSTUP_TOOLCHAIN "${RUSTUP_TOOLCHAIN}"
