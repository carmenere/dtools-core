function ctx_crate_cargo_sonar() {
  ctx_cargo_crate || return $?
  CRATE_NAME="cargo-sonar"
  CRATE_VERSION="1.3.0"
}

DT_BINDINGS+=(ctx_crate_cargo_sonar:cargo_sonar:cargo_install_methods)

function cargo_sonar() {
  cmd_exec cd "${MANIFEST_DIR}"
  cmd_exec $(cg_envs) cargo sonar --clippy-path "${CLIPPY_REPORT}" --audit-path "${AUDIT_REPORT}" \
      --deny-path "${DENY_REPORT}" --sonar-path "${SONAR_REPORT}"; }
