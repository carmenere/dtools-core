function rustup_envs() {
  local envs=(RUSTUP_TOOLCHAIN)
  echo "${envs[@]}"
}

rust_arch() {
  arch=$(uname -m)
  if [ "${arch}" = "arm64" ]; then
    arch="aarch64"
  fi
  echo ${arch}
}

rust_target_triple() {
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

rustup_install() {
  toolchain="${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}"
	cmd_exec "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${toolchain}"
}

rustup_component_add() { cmd_exec rustup component add ${RUSTUP_COMPONENTS[@]}; }
rustup_component_list() { cmd_exec rustup component list; }
rustup_default() { cmd_exec rustup default ${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}; }
rustup_init() { rustup_install && rustup_nightly_install && rustup_component_add; }
rustup_nightly_install() { cmd_exec rustup toolchain install ${NIGHTLY_VERSION}-${RUSTUP_TARGET_TRIPLE}; }
rustup_target_list() { cmd_exec rustup target list; }
rustup_toolchain_install() { cmd_exec rustup toolchain install ${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}; }
rustup_toolchain_list() { cmd_exec rustup toolchain list; }

function rustup_methods() {
  local methods=()
  methods+=(rustup_component_add)
  methods+=(rustup_default)
  methods+=(rustup_init)
  methods+=(rustup_install)
  methods+=(rustup_nightly_install)
  methods+=(rustup_toolchain_install)
  echo "${methods[@]}"
}

ctx_rustup() {
  RUSTUP_TOOLCHAIN="1.86.0"
  RUSTUP_TARGET_TRIPLE=$(rust_target_triple)
  RUSTUP_COMPONENTS=(clippy rustfmt)
  NIGHTLY_VERSION="nightly-2025-05-01"
}

DT_BINDINGS+=(ctx_rustup:1.86.0:rustup_methods)
