function ctx_crate_cargo_sonar() {
  ctx_crate_defaults
  CRATE_NAME="cargo-sonar"
  CRATE_VERSION="1.3.0"
}

dt_register "ctx_crate_cargo_sonar" "cargo_sonar" "$(cargo_install_methods)"

function _cargo_sonar_opts() {
  _cargo_shared_manifest_opts
  if [ -n "${CLIPPY_REPORT}" ]; then cmd+=(--clippy-path "${CLIPPY_REPORT}"); fi
  if [ -n "${AUDIT_REPORT}" ]; then cmd+=(--audit-path "${AUDIT_REPORT}"); fi
  if [ -n "${DENY_REPORT}" ]; then cmd+=(--deny-path "${DENY_REPORT}"); fi
  if [ -n "${SONAR_REPORT}" ]; then cmd+=(--sonar-path "${SONAR_REPORT}"); fi
}

function cargo_sonar() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  cd "${MANIFEST_DIR}"
  cmd=("$(dt_inline_envs "${_export_envs[@]}")")
  cmd+=(cargo sonar)
  _cargo_sonar_opts
  dt_exec ${fname} "${cmd[@]}"
}
