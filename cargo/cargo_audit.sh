function ctx_crate_cargo_audit() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local dt_ctx; ctx_prolog ${fname} || return $?; if is_cached ${fname}; then return 0; fi
  var CRATE_NAME "cargo-audit"
  var CRATE_VERSION "0.21.2"
  ctx_cargo_crate && ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_crate_cargo_audit:cargo_audit:cargo_install_methods)

function cargo_audit() {
  exec_cmd cd "$(MANIFEST_DIR)"
  exec_cmd $(cg_envs) cargo audit --$(MESSAGE_FORMAT) '>' "$(AUDIT_REPORT)"
}