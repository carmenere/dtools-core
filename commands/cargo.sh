####################################### CARGO BUILD|TEST|CLIPPY|FMT|DOC|CLEAN ##########################################
cg_inline_exclude() {
  local result exclude
  result=()
  for exclude in ${EXCLUDE[@]}; do
    result+=(--exclude "${exclude}")
  done
  echo "${result[@]}"
}

cg_inline_bins() {
  local result bin
  result=()
  for bin in ${BINS[@]}; do
    result+=(--bin "${bin}")
  done
  echo "${result[@]}"
}

cg_set_manifest() { if [ -n "${MANIFEST_DIR}" ] && [ -n "${MANIFEST}" ]; then echo "${MANIFEST_DIR}/${MANIFEST}"; fi; }
cg_build_mode() { if [ "${PROFILE}" = "release" ]; then echo "release"; else echo "debug"; fi; }
cg_features() { if [ -n "${FEATURES}" ]; then echo "--features '${FEATURES}'"; fi; }
cg_manifest() { if [ -n "${MANIFEST_PATH}" ]; then echo "--manifest-path ${MANIFEST_PATH}"; fi;}
cg_msg_format() { if [ -n "${MESSAGE_FORMAT}" ]; then echo "--message-format ${MESSAGE_FORMAT}"; fi; }
cg_nightly() { if [ -n "${NIGHTLY_VERSION}" ]; then echo "+${NIGHTLY_VERSION}"; fi; }
cg_profile() { if [ -n "${PROFILE}" ]; then echo "--profile ${PROFILE}"; fi; }
clippy_report() { if [ -n "${CLIPPY_REPORT}" ]; then echo ">${CLIPPY_REPORT}"; fi; }

# bin_dir can be:
#   ${CARGO_TARGET_DIR}/${CARGO_BUILD_TARGET}/${BUILD_MODE}
#   ${CARGO_TARGET_DIR}/${BUILD_MODE}
cg_bin_dir() {
  local bin_dir
  if [ -n "${CARGO_TARGET_DIR}" ]; then bin_dir="${CARGO_TARGET_DIR}"; else bin_dir="$(pwd)/target"; fi
  if [ -n "${CARGO_BUILD_TARGET}" ] && [ -n "${bin_dir}" ]; then
    bin_dir="${bin_dir}/${CARGO_BUILD_TARGET}"
  else
    bin_dir="${CARGO_BUILD_TARGET}"
  fi
  echo "${bin_dir}/${BUILD_MODE}"
}

cg_package() {
  if [ "${BUILD_AS}" = "workspace" ]; then
    echo "--workspace $(cg_inline_exclude)"
  else
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
  . "${DT_VARS}/cargo/apps/$1.sh"
  exec_cmd "$(inline_envs)" cargo build $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest)
)}
cargo_clean() {(
  set -eu
  . "${DT_VARS}/cargo/apps/$1.sh"
  exec_cmd "$(inline_envs)" cargo clean $(cg_profile) $(cg_manifest)
)}
cargo_clippy() {(
  set -eu
  . "${DT_VARS}/cargo/apps/$1.sh"
  exec_cmd "$(inline_envs)" cargo clippy $(cg_targets) $(cg_features) $(cg_profile) $(cg_msg_format) $(cg_manifest) \
    -- ${CLIPPY_LINTS} $(clippy_report)
)}
cargo_clippy_fix() {(
  set -eu
  . "${DT_VARS}/cargo/apps/$1.sh"
  exec_cmd "$(inline_envs)" cargo clippy $(cg_targets) $(cg_features) $(cg_profile) --fix --allow-staged \
    $(cg_msg_format) $(cg_manifest) -- ${CLIPPY_LINTS} $(clippy_report)
)}
cargo_doc() {(
  set -eu
  . "${DT_VARS}/cargo/apps/$1.sh"
  exec_cmd "$(inline_envs)" cargo doc $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest) \
    --no-deps --document-private-items
)}
cargo_doc_open() {(
  set -eu
  . "${DT_VARS}/cargo/apps/$1.sh"
  exec_cmd "$(inline_envs)" cargo doc $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest) \
    --no-deps --document-private-items --open
)}
cargo_fmt() {(
  set -eu
  . "${DT_VARS}/cargo/apps/$1.sh"
  exec_cmd "$(inline_envs)" cargo $(cg_nightly) fmt $(cg_msg_format) $(cg_manifest) -- --check
)}
cargo_fmt_fix() {(
  set -eu
  . "${DT_VARS}/cargo/apps/$1.sh"
  exec_cmd "$(inline_envs)" cargo $(cg_nightly) fmt $(cg_msg_format) $(cg_manifest)
)}
cargo_test() {(
  set -eu
  . "${DT_VARS}/cargo/apps/$1.sh"
  exec_cmd "$(inline_envs)" cargo test $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest)
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
  methods+=(cargo_build)
  methods+=(cargo_clean)
  methods+=(cargo_clippy)
  methods+=(cargo_clippy_fix)
  methods+=(cargo_doc)
  methods+=(cargo_doc_open)
  methods+=(cargo_fmt)
  methods+=(cargo_fmt_fix)
  methods+=(cargo_test)
  echo "${methods[@]}"
}

cmd_family_cargo_crates() {
  local methods=()
  methods+=(cargo_install)
  methods+=(cargo_uninstall)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_cargo"
autocomplete_reg_family "cmd_family_cargo_crates"
