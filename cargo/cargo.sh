# PROFILE_CARGO={ release | dev }, by default "release"
export PROFILE_CARGO="dev"
set_cargo_profile_dev() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  PROFILE_CARGO="dev"
  if is_var_changed PROFILE_CARGO; then drop_vars; fi && \
  dt_info ${fname} "PROFILE_CARGO=${PROFILE_CARGO}"
}

set_cargo_profile_release() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  PROFILE_CARGO="release"
  if is_var_changed PROFILE_CARGO; then drop_vars; fi && \
  dt_info ${fname} "PROFILE_CARGO=${PROFILE_CARGO}"
}

cargo_envs() {
  local envs=()
  envs+=(CARGO_BUILD_TARGET)
  envs+=(CARGO_TARGET_DIR)
  envs+=(RUSTFLAGS)
  echo "${envs[@]} $(rustup_envs)"
}

set_manifest() {
  if [ -n "$(MANIFEST_DIR)" ] && [ -n "$(MANIFEST)" ]; then echo "$(MANIFEST_DIR)/$(MANIFEST)"; fi
}

cg_build_mode() { if [ "$(PROFILE)" = "release" ]; then echo "release"; else echo "debug"; fi; }
cg_envs() { echo "$(inline_vars "$(BUILD_ENVS) $(cargo_envs)")"; }
cg_exclude() { echo $(inline_vals "$(EXCLUDE)" --exclude); }
cg_features() { if [ -n "$(FEATURES)" ]; then echo "--features '$(FEATURES)'"; fi; }
cg_manifest() { if [ -n "$(MANIFEST_PATH)" ]; then echo "--manifest-path $(MANIFEST_PATH)"; fi;}
cg_msg_format() { if [ -n "$(MESSAGE_FORMAT)" ]; then echo "--message-format $(MESSAGE_FORMAT)"; fi; }
cg_nightly() { if [ -n "$(NIGHTLY_VERSION)" ]; then echo "+$(NIGHTLY_VERSION)"; fi; }
cg_profile() { if [ -n "$(PROFILE)" ]; then echo "--profile $(PROFILE)"; fi; }
clippy_report() { if [ -n "$(CLIPPY_REPORT)" ]; then echo ">$(CLIPPY_REPORT)"; fi; }

# bin_dir can be:
#   $(CARGO_TARGET_DIR)/$(CARGO_BUILD_TARGET)/${BUILD_MODE}
#   $(CARGO_TARGET_DIR)/${BUILD_MODE}
cg_bin_dir() {
  local bin_dir
  if [ -n "$(CARGO_TARGET_DIR)" ]; then bin_dir="$(CARGO_TARGET_DIR)"; else bin_dir="$(pwd)/target"; fi
  if [ -n "$(CARGO_BUILD_TARGET)" ]; then bin_dir="${bin_dir}/$(CARGO_BUILD_TARGET)"; fi
  echo "${bin_dir}/$(cg_build_mode)"
}

cg_package() {
  if [ "$(BUILD_AS)" = "workspace" ]; then
    echo "--workspace $(cg_exclude)"
  else
    echo "--package $(PACKAGE)"
  fi
}

cg_targets() {
  # By default: --bins --lib
  # When no target selection options are given, cargo build will build all binary and library targets of the selected packages.
  # Binaries are skipped if they have required-features that are missing.
  echo "$(cg_package) $(inline_vals "$(BINS)" --bin)"
}

cargo_build() { exec_cmd $(cg_envs) cargo build $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest); }
cargo_clean() { exec_cmd $(cg_envs) cargo clean $(cg_profile) $(cg_manifest); }
cargo_clippy() { exec_cmd $(cg_envs) cargo clippy $(cg_targets) $(cg_features) $(cg_profile) $(cg_msg_format) $(cg_manifest) \
    -- $(CLIPPY_LINTS) $(clippy_report); }
cargo_clippy_fix() { exec_cmd $(cg_envs) cargo clippy $(cg_targets) $(cg_features) $(cg_profile) --fix --allow-staged \
    $(cg_msg_format) $(cg_manifest) -- $(CLIPPY_LINTS) $(clippy_report); }
cargo_doc() { exec_cmd $(cg_envs) cargo doc $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest) \
    --no-deps --document-private-items; }
cargo_doc_open() { exec_cmd $(cg_envs) cargo doc $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest) \
    --no-deps --document-private-items --open; }
cargo_fmt() { exec_cmd $(cg_envs) cargo $(cg_nightly) fmt $(cg_msg_format) $(cg_manifest) -- --check; }
cargo_fmt_fix() { exec_cmd $(cg_envs) cargo $(cg_nightly) fmt $(cg_msg_format) $(cg_manifest); }
cargo_test() { exec_cmd $(cg_envs) cargo test $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest) ; }

cargo_methods() {
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

cargo_uninstall() { exec_cmd cargo uninstall $(CRATE_NAME); }
cargo_install() { exec_cmd cargo install $(FLAGS) --version $(CRATE_VERSION) $(CRATE_NAME); }
cargo_cache_clean() { exec_cmd cargo cache -r all; }

cargo_install_methods() {
  local methods=()
  methods+=(cargo_install)
  methods+=(cargo_uninstall)
  echo "${methods[@]}"
}

ctx_cargo() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var BINS && \
  var BUILD_AS "package" && \
  var BUILD_ENVS && \
  var CARGO_BUILD_TARGET && \
  var CARGO_TARGET_DIR "${DT_PROJECT}/target" && \
  var CLIPPY_LINTS && \
  var CLIPPY_REPORT && \
  var EXCLUDE && \
  var FEATURES && \
  var MANIFEST 'Cargo.toml' && \
  var MANIFEST_DIR && \
  var MESSAGE_FORMAT && \
  var PACKAGE && \
  var PROFILE ${PROFILE_CARGO} && \
  var RUSTFLAGS && \
  # Depends on PROFILE
  var BUILD_MODE $(cg_build_mode) && \
  # Depends on CARGO_TARGET_DIR, CARGO_TARGET_DIR, BUILD_MODE
  var BINS_DIR $(cg_bin_dir) && \
  # Depends on both MANIFEST and MANIFEST_DIR
  var MANIFEST_PATH $(set_manifest) && \
  cache_ctx
}

ctx_cargo_crate() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var CRATE_NAME && \
  var CRATE_VERSION && \
  var FLAGS "--locked" && \
  cache_ctx
}