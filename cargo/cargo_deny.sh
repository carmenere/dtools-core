function ctx_crate_cargo_deny() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var CRATE_NAME "cargo-deny"
  var CRATE_VERSION "0.18.2"
  ctx_cargo_crate && ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_crate_cargo_deny:cargo_deny:cargo_install_methods)

function cargo_deny() {
  cmd_exec cd "$(MANIFEST_DIR)"
  cmd_exec $(cg_envs) cargo deny $(cg_msg_format) '2>' "$(DENY_REPORT)"
}
