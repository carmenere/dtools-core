function ctx_crate_cargo_audit() {
  ctx_cargo_crate || return $?
  CRATE_NAME="cargo-audit"
  CRATE_VERSION="0.21.2"
}

DT_BINDINGS+=(ctx_crate_cargo_audit:cargo_audit:cargo_install_methods)

function cargo_audit() {
  cmd_exec cd "${MANIFEST_DIR}"
  cmd_exec $(cg_envs) cargo audit --${MESSAGE_FORMAT} '>' "${AUDIT_REPORT}"
}