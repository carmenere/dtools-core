function ctx_crate_cargo_deny() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); dt_debug ${ctx} ">>>>> ctx=${ctx}, caller=?????"; set_caller $1; if is_cached; then return 0; fi
  var CRATE_NAME "cargo-deny"
  var CRATE_VERSION "0.18.2"
  ctx_cargo_crate ${caller} && cache_ctx
}

DT_BINDINGS+=(ctx_crate_cargo_deny:cargo_deny:cargo_install_methods)

function cargo_deny() {
  exec_cmd cd "$(MANIFEST_DIR)"
  exec_cmd $(cg_envs) cargo deny $(cg_msg_format) '2>' "$(DENY_REPORT)"
}
