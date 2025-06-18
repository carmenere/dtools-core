# PROFILE_CARGO={ release | dev }, by default "release"
export PROFILE_CARGO="dev"

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

cargo_build() { cmd_exec $(cg_envs) cargo build $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest); }
cargo_clean() { cmd_exec $(cg_envs) cargo clean $(cg_profile) $(cg_manifest); }
cargo_clippy() { cmd_exec $(cg_envs) cargo clippy $(cg_targets) $(cg_features) $(cg_profile) $(cg_msg_format) $(cg_manifest) \
    -- $(CLIPPY_LINTS) $(clippy_report); }
cargo_clippy_fix() { cmd_exec $(cg_envs) cargo clippy $(cg_targets) $(cg_features) $(cg_profile) --fix --allow-staged \
    $(cg_msg_format) $(cg_manifest) -- $(CLIPPY_LINTS) $(clippy_report); }
cargo_doc() { cmd_exec $(cg_envs) cargo doc $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest) \
    --no-deps --document-private-items; }
cargo_doc_open() { cmd_exec $(cg_envs) cargo doc $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest) \
    --no-deps --document-private-items --open; }
cargo_fmt() { cmd_exec $(cg_envs) cargo $(cg_nightly) fmt $(cg_msg_format) $(cg_manifest) -- --check; }
cargo_fmt_fix() { cmd_exec $(cg_envs) cargo $(cg_nightly) fmt $(cg_msg_format) $(cg_manifest); }
cargo_test() { cmd_exec $(cg_envs) cargo test $(cg_targets) $(cg_features) $(cg_profile) $(cg_manifest) ; }

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

cargo_uninstall() { cmd_exec cargo uninstall $(CRATE_NAME); }
cargo_install() { cmd_exec cargo install $(FLAGS) --version $(CRATE_VERSION) $(CRATE_NAME); }
cargo_cache_clean() { cmd_exec cargo cache -r all; }

cargo_install_methods() {
  local methods=()
  methods+=(cargo_install)
  methods+=(cargo_uninstall)
  echo "${methods[@]}"
}

ctx_cargo() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var BINS
  var BUILD_AS "package"
  var BUILD_ENVS
  var CARGO_BUILD_TARGET
  var CARGO_TARGET_DIR "${DT_PROJECT}/target"
  var CLIPPY_LINTS
  var CLIPPY_REPORT
  var EXCLUDE
  var FEATURES
  var MANIFEST 'Cargo.toml'
  var MANIFEST_DIR
  var MESSAGE_FORMAT
  var PACKAGE
  var PROFILE $(PROFILE_CARGO)
  var RUSTFLAGS
  # Depends on PROFILE
  var BUILD_MODE $(cg_build_mode)
  # Depends on CARGO_TARGET_DIR, CARGO_TARGET_DIR, BUILD_MODE
  var BINS_DIR $(cg_bin_dir)
  # Depends on both MANIFEST and MANIFEST_DIR
  var MANIFEST_PATH $(set_manifest)
  ctx_epilog ${fname}
}

ctx_cargo_crate() {
  CRATE_NAME=
  CRATE_VERSION=
  FLAGS="--locked"
}