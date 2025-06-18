function ctx_crate_cargo_sonar() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var CRATE_NAME "cargo-sonar"
  var CRATE_VERSION "1.3.0"
  ctx_cargo_crate && ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_crate_cargo_sonar:cargo_sonar:cargo_install_methods)

function cargo_sonar() {
  cmd_exec cd "$(MANIFEST_DIR)"
  cmd_exec $(cg_envs) cargo sonar --clippy-path "$(CLIPPY_REPORT)" --audit-path "$(AUDIT_REPORT)" \
      --deny-path "$(DENY_REPORT)" --sonar-path "$(SONAR_REPORT)"; }
