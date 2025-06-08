function ctx_crate_cargo_audit() {
  ctx_crate_defaults
  CRATE_NAME="cargo-audit"
  CRATE_VERSION="0.21.2"
}

dt_register "ctx_crate_cargo_audit" "cargo_audit" "${cargo_install_methods[@]}"

function _cargo_audit_opts() {
  _cargo_shared_manifest_opts
  if [ -z "${MESSAGE_FORMAT}" ]; then cmd+=(--json); else cmd+=(--"${MESSAGE_FORMAT}"); fi
  if [ -n "${AUDIT_REPORT}" ]; then cmd+=('>' "${AUDIT_REPORT}"); fi
}

function cargo_audit() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  cd "${MANIFEST_DIR}"
  cmd=("$(dt_inline_envs "${_export_envs[@]}")")
  cmd+=(cargo audit)
  _cargo_audit_opts
  dt_exec ${fname} "${cmd[@]}"
}
