# PROFILE = { release | dev }, by default "dev"
# BUILD_AS = { package | workspace}, by default "package"

# rustup vars
. <(. ${DT_VARS}/rustup/1.86.sh
  echo "RUSTUP_TOOLCHAIN=${RUSTUP_TOOLCHAIN}"
  echo "NIGHTLY_VERSION=${NIGHTLY_VERSION}"
)

declare -A envs
ENVS=()

BINS=
#BUILD_AS
CARGO_BUILD_TARGET=
CARGO_TARGET_DIR="${DT_PROJECT}/target"
CLIPPY_LINTS=
CLIPPY_REPORT=
EXCLUDE=
FEATURES=
MANIFEST="Cargo.toml"
MANIFEST_DIR=
MESSAGE_FORMAT=
PACKAGE=
PROFILE="dev"
RUSTFLAGS=

# Depends on PROFILE
BUILD_MODE=$(cg_build_mode)
# Depends on CARGO_TARGET_DIR, CARGO_TARGET_DIR, BUILD_MODE
BINS_DIR=$(cg_bin_dir)
# Depends on both MANIFEST and MANIFEST_DIR
MANIFEST_PATH=$(cg_set_manifest)

# cargo envs
#add_env RUSTFLAGS "${RUSTFLAGS}"
#add_env CARGO_BUILD_TARGET "${CARGO_BUILD_TARGET}"
add_env CARGO_TARGET_DIR "${CARGO_TARGET_DIR}"