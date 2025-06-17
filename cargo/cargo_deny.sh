function ctx_crate_cargo_deny() {
  ctx_cargo_crate || return $?
  CRATE_NAME="cargo-deny"
  CRATE_VERSION="0.18.2"
}

DT_BINDINGS+=(ctx_crate_cargo_deny:cargo_deny:cargo_install_methods)

function cargo_deny() {
  cmd_exec cd "${MANIFEST_DIR}"
  cmd_exec $(cg_envs) cargo deny $(cg_msg_format) '2>' "${DENY_REPORT}"
}
