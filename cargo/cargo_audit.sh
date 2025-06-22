function ctx_crate_cargo_audit() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); dt_debug ${ctx} ">>>>> ctx=${ctx}, caller=?????"; set_caller $1; if is_cached; then return 0; fi
  var CRATE_NAME "cargo-audit"
  var CRATE_VERSION "0.21.2"
  ctx_cargo_crate ${caller} && cache_ctx
}

DT_BINDINGS+=(ctx_crate_cargo_audit:cargo_audit:cargo_install_methods)

function cargo_audit() {
  exec_cmd cd "$(MANIFEST_DIR)"
  exec_cmd $(cg_envs) cargo audit --$(MESSAGE_FORMAT) '>' "$(AUDIT_REPORT)"
}