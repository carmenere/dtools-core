rustup_envs=(RUSTUP_TOOLCHAIN)

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
  if [ -n "$1" ]; then local mode="$1"; else local mode='exec'; fi
  local toolchain="${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}"
	local cmd="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${toolchain}"

	dt_exec_or_echo $mode "${cmd}"
}

function rustup_toolchain_install() {
  if [ -n "$1" ]; then local mode="$1"; else local mode='exec'; fi
  local toolchain="${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}"
	local cmd="rustup toolchain install ${toolchain}"
	dt_exec_or_echo $mode "${cmd}"
}

function rustup_nightly_install() {
  if [ -n "$1" ]; then local mode="$1"; else local mode='exec'; fi
  local toolchain="${NIGHTLY_VERSION}-${RUSTUP_TARGET_TRIPLE}"
	local cmd="rustup toolchain install ${toolchain}"
	dt_exec_or_echo $mode "${cmd}"
}

function rustup_default() {
  if [ -n "$1" ]; then local mode="$1"; else local mode='exec'; fi
  local toolchain="${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}"
	local cmd="rustup default ${toolchain}"
	dt_exec_or_echo $mode "${cmd}"
}

function rustup_component_add() {
  if [ -n "$1" ]; then local mode="$1"; else local mode='exec'; fi
	local cmd="rustup component add '${RUSTUP_COMPONENTS[@]}'"
	dt_exec_or_echo $mode "${cmd}"
}

function rustup_toolchain_list() {
  dt_exec_or_echo "rustup toolchain list"
}

function rustup_target_list() {
  dt_exec_or_echo "rustup target list"
}

function rustup_component_list() {
  dt_exec_or_echo "rustup component list"
}

function ctx_rustup() {
  RUSTUP_TOOLCHAIN="1.86.0"
  RUSTUP_TARGET_TRIPLE=$(rust_target_triple)
  RUSTUP_COMPONENTS=(clippy rustfmt)
  NIGHTLY_VERSION="nightly-2025-05-01"
  _inline_envs=($rustup_envs[@])
  _export_envs+=(${_inline_envs[@]})
}

rustup_methods=()

rustup_methods+=(rustup_install)
rustup_methods+=(rustup_toolchain_install)
rustup_methods+=(rustup_nightly_install)
rustup_methods+=(rustup_default)
rustup_methods+=(rustup_component_add)

dt_register "ctx_rustup" "1_86" "${rustup_methods[@]}"
