. ${DT_VARS}/cargo/apps/defaults.sh

BUILD_AS="workspace"
CLIPPY_LINTS="-Dwarnings"
MANIFEST_DIR="${DT_PROJECT}"

cg_add_bin "tetrix-api"
add_env BUILD_VERSION "$(git_build_version)"
