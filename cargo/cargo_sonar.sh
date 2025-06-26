function ctx_crate_cargo_sonar() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var CRATE_NAME "cargo-sonar" && \
  var CRATE_VERSION "1.3.0" && \
  ctx_cargo_crate ${caller} && cache_ctx
}

DT_BINDINGS+=(ctx_crate_cargo_sonar:cargo_sonar:cargo_install_methods)

function cargo_sonar() {
  exec_cmd cd "$(MANIFEST_DIR)"
  exec_cmd $(cg_envs) cargo sonar --clippy-path "$(CLIPPY_REPORT)" --audit-path "$(AUDIT_REPORT)" \
      --deny-path "$(DENY_REPORT)" --sonar-path "$(SONAR_REPORT)"; }
