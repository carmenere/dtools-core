cargo_envs+=(CARGO_BUILD_TARGET CARGO_TARGET_DIR RUSTFLAGS)

function _cargo_pkg_opt() {
  if [ -n "${PACKAGE}" ]; then
    # If package is specified use --package
    cmd+=(--package "${PACKAGE}")
  fi
}

function _cargo_workspace_opt() {
  if [ -z "${PACKAGE}" ]; then
    # If package is NOT specified use --workspace with --exclude
    cmd+=(--workspace)
    for exc in ${EXCLUDE}; do
      cmd+=(--exclude ${exc})
    done
  fi
}

function _cargo_target_selection() {
  # By default: --bins --lib
  # When no target selection options are given, cargo build will build all binary and library targets of the selected packages.
  # Binaries are skipped if they have required-features that are missing.
  if [ -z "${BINS}" ]; then return 0; fi
  for bin in ${BINS}; do
    cmd+=(--bin "${bin}")
  done
}

function _cargo_shared_manifest_opts() {
  if [ "${FROZEN}" = "y" ]; then cmd+=(--frozen); fi
  if [ "${LOCKED}" = "y" ]; then cmd+=(--locked); fi
  if [ "${OFFLINE}" = "y" ]; then cmd+=(--offline); fi
}

function _cargo_features_opts() {
  if [ "${ALL_FEATURES}" = "y" ]; then cmd+=(--all-features); fi
  if [ "${NO_DEFAULT_FEATURES}" = "y" ]; then cmd+=(--no-default-features); fi
  if [ -n "${FEATURES}" ]; then cmd+=(--features "'${FEATURES}'"); fi
}

function _cargo_install_opts() {
  _cargo_shared_manifest_opts
  if [ "${FORCE}" = "y" ]; then cmd+=(--force); fi
}

#function cargo_uninstall_opts() {
#  _cargo_shared_manifest_opts
#}

function _cargo_fmt_opts() {
  _cargo_pkg_opt
  if [ -n "${MESSAGE_FORMAT}" ]; then cmd+=(--message-format "${MESSAGE_FORMAT}"); fi
  if [ -n "${MANIFEST_PATH}" ]; then cmd+=(--manifest-path "${MANIFEST_PATH}"); fi
}

function _cargo_shared_build_check_test_doc_opts() {
  _cargo_pkg_opt
  _cargo_workspace_opt
  _cargo_target_selection
  _cargo_features_opts
  if [ "${IGNORE_RUST_VERSION}" = "y" ]; then cmd+=(--ignore-rust-version); fi
  if [ -n "${MESSAGE_FORMAT}" ]; then cmd+=(--message-format "${MESSAGE_FORMAT}"); fi
  if [ -n "${PROFILE}" ]; then cmd+=(--profile "${PROFILE}"); fi
  if [ -n "${MANIFEST_PATH}" ]; then cmd+=(--manifest-path "${MANIFEST_PATH}"); fi
}

function _cargo_build_opts() {
  _cargo_shared_manifest_opts
  _cargo_shared_build_check_test_doc_opts
}

function _cargo_clippy_opts() {
  _cargo_shared_manifest_opts
  _cargo_shared_build_check_test_doc_opts
  clippy_opts=()
  if [ -n "${CLIPPY_LINTS}" ]; then clippy_opts+=(${CLIPPY_LINTS}); fi
  if [ -n "${CLIPPY_REPORT}" ]; then clippy_opts+=('1>' "${CLIPPY_REPORT}"); fi
  if [ -n "${clippy_opts}" ]; then cmd+=("-- ${clippy_opts}"); fi
}

function _cargo_test_opts() {
  _cargo_shared_manifest_opts
  _cargo_shared_build_check_test_doc_opts
}

function _cargo_doc_opts() {
  _cargo_shared_manifest_opts
  _cargo_shared_build_check_test_doc_opts
}

function _cargo_clean_opts() {
  _cargo_pkg_opt
  _cargo_shared_manifest_opts
  if [ -n "${PROFILE}" ]; then cmd+=(--profile "${PROFILE}"); fi
  if [ -n "${MANIFEST_PATH}" ]; then cmd+=(--manifest-path "${MANIFEST_PATH}"); fi
}

function cargo_cache_clean() {
  cargo cache -r all
}

function cargo_install() {
  dt_err_if_empty $0 "CRATE_NAME"; exit_on_err $0 $? || return $?
  dt_err_if_empty $0 "CRATE_VERSION"; exit_on_err $0 $? || return $?
  cmd=("$(dt_inline_envs)")
  cmd=(cargo install)
  cmd+=(--version "${CRATE_VERSION}")
  _cargo_install_opts
  cmd+=(${CRATE_NAME})
  dt_exec_or_echo "${cmd}" $mode
}

function cargo_uninstall() {
  dt_err_if_empty $0 "CRATE_NAME"; exit_on_err $0 $? || return $?
  cmd=("$(dt_inline_envs)")
  cmd=(cargo uninstall)
  cmd+=(${CRATE_NAME})
  dt_exec_or_echo "${cmd}" $mode
}

function cargo_profile() {
  profile="dev"

  if [ "$(get_profile release)" = "release" ]; then
      profile="release"
  fi
  echo "${profile}"
}

function cargo_build_mode() {
  mode="debug"
  if [ "$(get_profile release)" = "release" ]; then
      mode="release"
  fi
  echo "${mode}"
}

# BINS_DIR can be:
#   ${CARGO_TARGET_DIR}/${CARGO_BUILD_TARGET}/${BUILD_MODE}
#   ${CARGO_TARGET_DIR}/${BUILD_MODE}
function cargo_bin_dir() {
  if [ -n "${CARGO_TARGET_DIR}" ]; then
    bin_dir="${CARGO_TARGET_DIR}"
  else
    bin_dir="$(pwd)/target"
  fi
  if [ -n "${CARGO_BUILD_TARGET}" ]; then bin_dir="${bin_dir}/${CARGO_BUILD_TARGET}"; fi
  if [ -n "${BUILD_MODE}" ]; then
    bin_dir="${bin_dir}/${BUILD_MODE}"
  else
    bin_dir="${bin_dir}/$(cargo_build_mode)"
  fi
  echo "${bin_dir}"
}

function cargo_build() {
  local _inline_envs=(${rustup_envs[@]} ${cargo_envs[@]})
  _inline_envs+=("${_app_compile_envs}")
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo build)
  _cargo_build_opts
  dt_exec_or_echo "${cmd}" $mode
}

function cargo_fmt() {
  local _inline_envs=(${rustup_envs[@]} ${cargo_envs[@]})
  _inline_envs+=("${_app_compile_envs}")
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo)
  if [ -n "${NIGHTLY_VERSION}" ]; then cmd+=("+${NIGHTLY_VERSION}"); fi
  cmd+=(fmt)
  _cargo_fmt_opts
  cmd+=(-- --check)
  dt_exec_or_echo "${cmd}" $mode
}

function cargo_fmt_fix() {
  local _inline_envs=(${rustup_envs[@]} ${cargo_envs[@]})
  _inline_envs+=("${_app_compile_envs}")
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo)
  if [ -n "${NIGHTLY_VERSION}" ]; then cmd+=("+${NIGHTLY_VERSION}"); fi
  cmd+=(fmt)
  _cargo_fmt_opts
  dt_exec_or_echo "${cmd}" $mode
}

function cargo_test() {
  local _inline_envs=(${rustup_envs[@]} ${cargo_envs[@]})
  _inline_envs+=("${_app_compile_envs}")
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo test)
  _cargo_test_opts
  dt_exec_or_echo "${cmd}" $mode
}

# "cargo clippy" uses "cargo check" under the hood.
function cargo_clippy() {
  local _inline_envs=(${rustup_envs[@]} ${cargo_envs[@]})
  _inline_envs+=("${_app_compile_envs}")
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo clippy)
  _cargo_clippy_opts
  dt_exec_or_echo "${cmd}" $mode
}

function cargo_clippy_fix() {
  local _inline_envs=(${rustup_envs[@]} ${cargo_envs[@]})
  _inline_envs+=("${_app_compile_envs}")
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo clippy --fix --allow-staged)
  _cargo_clippy_opts
  dt_exec_or_echo "${cmd}" $mode
}

function cargo_doc() {
  local _inline_envs=(${rustup_envs[@]} ${cargo_envs[@]})
  _inline_envs+=("${_app_compile_envs}")
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo doc --no-deps --document-private-items)
  _cargo_doc_opts
  dt_exec_or_echo "${cmd}" $mode
}

function cargo_doc_open() {
  local _inline_envs=(${rustup_envs[@]}${cargo_envs[@]})
  _inline_envs+=("${_app_compile_envs}")
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo doc --no-deps --document-private-items --open)
  _cargo_doc_opts
  dt_exec_or_echo "${cmd}" $mode
}

function cargo_clean() {
  local _inline_envs=(${rustup_envs[@]} ${cargo_envs[@]})
  _inline_envs+=("${_app_compile_envs}")
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo clean)
  _cargo_clean_opts
  dt_exec_or_echo "${cmd}" $mode
}

# BINS is an array, by default BINS=()
function ctx_cargo() {
  ctx_rustup
  # inherited from ctx_rustup
  #  RUSTUP_TOOLCHAIN=
  #  NIGHTLY_VERSION=
  # _envs
  BINS=()
  BUILD_MODE=$(cargo_build_mode)
  CARGO_BUILD_TARGET=
  CARGO_TARGET_DIR="$(pwd)/target"
  CLIPPY_LINTS=()
  CLIPPY_REPORT=
  EXCLUDE=()
  FEATURES=()
  MANIFEST='Cargo.toml'
  MANIFEST_DIR=
  MANIFEST_PATH=
  MESSAGE_FORMAT=
  PACKAGE=
  PROFILE=$(cargo_profile)
  RUSTFLAGS=''

  # Flags, can be y or n
  ALL_FEATURES=
  FORCE=
  FROZEN=
  IGNORE_RUST_VERSION=
  LOCKED=
  NO_DEFAULT_FEATURES=
  OFFLINE=

  # BINS_DIR depends on CARGO_TARGET_DIR, CARGO_TARGET_DIR, BUILD_MODE
  BINS_DIR=$(cargo_bin_dir)

  # MANIFEST_PATH depends on both MANIFEST and MANIFEST_DIR
  if [ -n "${MANIFEST_DIR}" ] && [ -n "${MANIFEST}" ]; then MANIFEST_PATH="${MANIFEST_DIR}/${MANIFEST}"; fi

  _export_envs=(${rustup_envs[@]} ${cargo_envs[@]})
}

cargo_methods=()

cargo_methods+=(cargo_build)
cargo_methods+=(cargo_clippy)
cargo_methods+=(cargo_clippy_fix)
cargo_methods+=(cargo_doc)
cargo_methods+=(cargo_doc_open)
cargo_methods+=(cargo_fmt)
cargo_methods+=(cargo_fmt_fix)
cargo_methods+=(cargo_test)

cargo_install_methods=()

cargo_install_methods+=(cargo_install)
cargo_install_methods+=(cargo_uninstall)