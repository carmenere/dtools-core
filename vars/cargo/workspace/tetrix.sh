. ${DT_VARS}/cargo/workspace/defaults.sh

BINS+=("tetrix-api")
#CLIPPY_LINTS+=("-Dwarnings")
MANIFEST_DIR="${DT_PROJECT}"

add_env BUILD_VERSION "$(git_build_version)"
add_env RUSTUP_TOOLCHAIN "${RUSTUP_TOOLCHAIN}"
