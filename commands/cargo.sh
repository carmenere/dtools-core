####################################### CARGO BUILD|TEST|CLIPPY|FMT|DOC|CLEAN ##########################################
cg_inline_exclude() {
  local result exclude
  result=()
  for exclude in "${EXCLUDE[@]}"; do
    result+=(--exclude "${exclude}")
  done
  echo "${result[@]}"
}

cg_inline_bins() {
  local result bin
  result=()
  for bin in "${BINS[@]}"; do
    result+=(--bin "${bin}")
  done
  echo "${result[@]}"
}

cg_build_mode() { if [ "${PROFILE}" = "release" ]; then echo "release"; else echo "debug"; fi; }
cg_features() { if [ -n "${FEATURES}" ]; then echo "--features '${FEATURES[@]}'"; fi; }
cg_manifest() { if [ -n "${MANIFEST_DIR}" ] && [ -n "${MANIFEST}" ]; then echo "--manifest-path ${MANIFEST_DIR}/${MANIFEST}"; fi; }
cg_msg_format() { if [ -n "${MESSAGE_FORMAT}" ]; then echo "--message-format ${MESSAGE_FORMAT}"; fi; }
cg_nightly() { if [ -n "${NIGHTLY_VERSION}" ]; then echo "+${NIGHTLY_VERSION}"; fi; }
cg_profile() { if [ -n "${PROFILE}" ]; then echo "--profile ${PROFILE}"; fi; }
cg_clippy_lints() { if [ -n "${CLIPPY_LINTS}" ]; then echo "${CLIPPY_LINTS[@]}"; fi; }
cg_clippy_report() { if [ -n "${CLIPPY_REPORT}" ]; then echo ">${CLIPPY_REPORT}"; fi; }

# bin_dir can be:
#   ${CARGO_TARGET_DIR}/${CARGO_BUILD_TARGET}/${BUILD_MODE}
#   ${CARGO_TARGET_DIR}/${BUILD_MODE}
cg_bin_dir() {
  local bin_dir
  if [ -n "${CARGO_TARGET_DIR}" ]; then
    bin_dir="${CARGO_TARGET_DIR}"
  else
    bin_dir="$(pwd)/target"
  fi
  if [ -n "${CARGO_BUILD_TARGET}" ]; then
    bin_dir="${bin_dir}/${CARGO_BUILD_TARGET}"
  fi
  echo "${bin_dir}/${BUILD_MODE}"
}

cg_package() {
  if [ "${BUILD_AS}" = "workspace" ]; then
    echo "--workspace $(cg_inline_exclude)"
  elif [ "${BUILD_AS}" = "package" ]; then
    echo "--package ${PACKAGE}"
  fi
}

cg_targets() {
  # By default: --bins --lib
  # When no target selection options are given, cargo build will build all binary and library targets of the selected packages.
  # Binaries are skipped if they have required-features that are missing.
  echo "$(cg_package) $(cg_inline_bins)"
}

cargo_build() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo build $(cg_targets) $(cg_features) $(cg_profile)
)}

cargo_clean() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo clean $(cg_profile)
)}

cargo_clippy() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo clippy $(cg_targets) $(cg_features) $(cg_profile) $(cg_msg_format) \
    -- $(cg_clippy_lints) $(cg_clippy_report)
)}

cargo_clippy_fix() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo clippy $(cg_targets) $(cg_features) $(cg_profile) --fix --allow-staged \
    $(cg_msg_format) -- $(cg_clippy_lints) $(cg_clippy_report)
)}

cargo_doc() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo doc $(cg_targets) $(cg_features) $(cg_profile) \
    --no-deps --document-private-items
)}

cargo_doc_open() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo doc $(cg_targets) $(cg_features) $(cg_profile) \
    --no-deps --document-private-items --open
)}

cargo_fmt() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo $(cg_nightly) fmt -- --check
)}

cargo_fmt_fix() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo $(cg_nightly) fmt
)}

cargo_test_unit() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo test --lib $(cg_targets) $(cg_features) $(cg_profile)
)}

cargo_test_integration() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo test --test "'*'" $(cg_targets) $(cg_features) $(cg_profile)
)}

cargo_all() {(
  set -eu
  cargo_fmt $1 $2
  cargo_clippy $1 $2
  cargo_build $1 $2
  cargo_test_unit $1 $2
  cargo_doc $1 $2
)}

################################################# CARGO SQLX PREPARE ###################################################
function cargo_sqlx_prepare() {(
  set -eu
  . "${DT_VARS}/cargo/$1/$2.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  local w=
  if [ "${BUILD_AS}" = "workspace" ]; then
    w="--workspace"
  fi
  exec_cmd "$(inline_envs)" cargo sqlx prepare ${w}
)}

############################################### CARGO INSTALL|UNINSTALL ################################################
cargo_uninstall() {(
  set -eu
  . "${DT_VARS}/cargo/crates/$1.sh"
  exec_cmd cargo uninstall ${CRATE_NAME}
)}

cargo_install() {(
  set -eu
  . "${DT_VARS}/cargo/crates/$1.sh"
  exec_cmd cargo install ${FLAGS} --version ${CRATE_VERSION} ${CRATE_NAME}
)}

cargo_cache_clean() { exec_cmd cargo cache -r all; }

##################################################### AUTOCOMPLETE #####################################################
cmd_family_cargo() {
  local methods=()
  methods+=(cargo_all)
  methods+=(cargo_build)
  methods+=(cargo_clean)
  methods+=(cargo_clippy)
  methods+=(cargo_clippy_fix)
  methods+=(cargo_doc)
  methods+=(cargo_doc_open)
  methods+=(cargo_fmt)
  methods+=(cargo_fmt_fix)
  methods+=(cargo_test_unit)
  methods+=(cargo_sqlx_prepare)
  methods+=(cargo_test_integration)
  echo "${methods[@]}"
}

cmd_family_cargo_crates() {
  local methods=()
  methods+=(cargo_install)
  methods+=(cargo_uninstall)
  echo "${methods[@]}"
}

autocomplete_cmd_family_cargo() {
  local cur prev
  local options
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case ${COMP_CWORD} in
    1)
      COMPREPLY=($(compgen -W "workspace package" -- ${cur}))
      ;;
    2)
      case ${prev} in
        workspace)
          options="${DT_AUTOCOMPLETIONS[cmd_family_cargo_workspace]}"
          COMPREPLY=( $(compgen -W "${options}" -- "${cur_word}") )
          ;;
        package)
          options="${DT_AUTOCOMPLETIONS[cmd_family_cargo_package]}"
          COMPREPLY=( $(compgen -W "${options}" -- "${cur_word}") )
          ;;
      esac
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}

autocomplete_reg_family "cmd_family_cargo"
autocomplete_reg_family "cmd_family_cargo_crates"
