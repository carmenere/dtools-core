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
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "RUSTUP_TOOLCHAIN" || return $?
  err_if_empty ${fname} "RUSTUP_TARGET_TRIPLE" || return $?
  local toolchain="${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}"
	local cmd="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${toolchain}"

	cmd_exec "${cmd}"
}

function rustup_toolchain_install() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "RUSTUP_TOOLCHAIN" || return $?
  err_if_empty ${fname} "RUSTUP_TARGET_TRIPLE" || return $?
  local toolchain="${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}"
	local cmd="rustup toolchain install ${toolchain}"
	cmd_exec "${cmd}" && rustup_nightly_install
}

function rustup_nightly_install() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "NIGHTLY_VERSION" || return $?
  err_if_empty ${fname} "RUSTUP_TARGET_TRIPLE" || return $?
	if [ -z "${NIGHTLY_VERSION}" ]; then return 0; fi
  local toolchain="${NIGHTLY_VERSION}-${RUSTUP_TARGET_TRIPLE}"
  local cmd="rustup toolchain install ${toolchain}"
	cmd_exec "${cmd}"
}

function rustup_default() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "RUSTUP_TOOLCHAIN" || return $?
  err_if_empty ${fname} "RUSTUP_TARGET_TRIPLE" || return $?
  local toolchain="${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}"
	local cmd="rustup default ${toolchain}"
	cmd_exec "${cmd}"
}

function rustup_component_add() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "RUSTUP_COMPONENTS" || return $?
	local cmd="rustup component add ${RUSTUP_COMPONENTS[@]}"
	cmd_exec "${cmd}"
}

function rustup_toolchain_list() {
  cmd_exec "rustup toolchain list"
}

function rustup_target_list() {
  cmd_exec "rustup target list"
}

function rustup_component_list() {
  cmd_exec "rustup component list"
}

function ctx_rustup() {
  RUSTUP_TOOLCHAIN="1.86.0"
  RUSTUP_TARGET_TRIPLE=$(rust_target_triple)
  RUSTUP_COMPONENTS=(clippy rustfmt)
  NIGHTLY_VERSION="nightly-2025-05-01"
  _export_envs=($rustup_envs[@])
}

rustup_methods=()

rustup_methods+=(rustup_install)
rustup_methods+=(rustup_toolchain_install)
rustup_methods+=(rustup_nightly_install)
rustup_methods+=(rustup_default)
rustup_methods+=(rustup_component_add)

register "ctx_rustup" "1_86" "${rustup_methods[@]}"
