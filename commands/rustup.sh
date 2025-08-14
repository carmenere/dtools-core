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

rustup_install() {(
  set -eu; . "${DT_VARS}/rustup/$1.sh"
  toolchain="${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}"
	exec_cmd "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${toolchain}"
)}

rustup_component_add() {(
  set -eu; . "${DT_VARS}/rustup/$1.sh"
  exec_cmd rustup component add "${RUSTUP_COMPONENTS[@]}"
)}

rustup_component_list() {(
  set -eu; . "${DT_VARS}/rustup/$1.sh"
  exec_cmd rustup component list
)}

rustup_default() {(
  set -eu; . "${DT_VARS}/rustup/$1.sh"
  exec_cmd rustup default ${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}
)}

rustup_nightly_install() {(
  set -eu; . "${DT_VARS}/rustup/$1.sh"
  exec_cmd rustup toolchain install ${NIGHTLY_VERSION}-${RUSTUP_TARGET_TRIPLE}
)}

rustup_target_list() {(
  set -eu; . "${DT_VARS}/rustup/$1.sh"
  exec_cmd rustup target list
)}

rustup_toolchain_install() {(
  set -eu; . "${DT_VARS}/rustup/$1.sh"
  exec_cmd rustup toolchain install ${RUSTUP_TOOLCHAIN}-${RUSTUP_TARGET_TRIPLE}
)}

rustup_toolchain_list() {(
  set -eu; . "${DT_VARS}/rustup/$1.sh"
  exec_cmd rustup toolchain list
)}

rustup_init() {
  (
    set -eu; . "${DT_VARS}/rustup/$1.sh"
    rustup_install $1
  )
  cargo_load_env || return $?
  (
    set -eu; . "${DT_VARS}/rustup/$1.sh"
    rustup_nightly_install $1
    rustup_component_add $1
  )
}

cargo_load_env() {
  . "${HOME}/.cargo/env"
}

function cmd_family_rustup() {
  local methods=()
  methods+=(rustup_component_add)
  methods+=(rustup_default)
  methods+=(rustup_init)
  methods+=(rustup_install)
  methods+=(rustup_nightly_install)
  methods+=(rustup_toolchain_install)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_rustup"
