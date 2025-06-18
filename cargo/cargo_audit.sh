function ctx_crate_cargo_audit() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var CRATE_NAME "cargo-audit"
  var CRATE_VERSION "0.21.2"
  ctx_cargo_crate && ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_crate_cargo_audit:cargo_audit:cargo_install_methods)

function cargo_audit() {
  cmd_exec cd "$(MANIFEST_DIR)"
  cmd_exec $(cg_envs) cargo audit --$(MESSAGE_FORMAT) '>' "$(AUDIT_REPORT)"
}