function rust_arch() {
  arch=$(uname -m)
  if [ "${arch}" = "arm64" ]; then
    arch="aarch64"
  fi
  echo $arch
}

function rust_target_triple() {
  if [ "$(os_name)" = "ubuntu" ]; then
    echo "$(rust_arch)-unknown-linux-gnu"
  elif [ "$(os_name)" = "alpine" ]; then
    echo "$(rust_arch)-unknown-linux-musl"
  elif [ "$(os_name)" = "macos" ]; then
    echo "$(rust_arch)-apple-darwin"
  elif [ "$(os_kernel)" = "Linux" ]; then
    echo "x86_64-unknown-linux-gnu"
  fi
}

function rustup_install() {
  ctx_rustup
  toolchain=${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE};
	echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${toolchain}"
}

function rustup_toolchain_install() {
  toolchain=$1; if [ -z "${toolchain}" ]; then ctx_rustup; toolchain=${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}; fi
	echo "rustup toolchain install ${toolchain}"
}

function rustup_default() {
  toolchain=$1; if [ -z "${toolchain}" ]; then ctx_rustup; toolchain=${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}; fi
	echo "rustup default ${toolchain}"
}

function rustup_component_add() {
  components=$1; if [ -z "$components" ]; then ctx_rustup; components="'${RUSTUP_COMPONENTS}'"; fi
	echo "rustup component add ${components}"
}

function ctx_rustup() {
  RUSTUP_TOOLCHAIN="1.86.0"
  RUSTUP_TARGET_TRIPLE=$(rust_target_triple)
  RUSTUP_COMPONENTS="clippy rustfmt"
  NIGHTLY_VERSION="nightly-2025-05-01"
  _export_envs=(
    RUSTUP_TOOLCHAIN
  )
}