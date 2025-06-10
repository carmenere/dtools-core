function ctx_crate_cargo_deny() {
  ctx_crate_defaults
  CRATE_NAME="cargo-deny"
  CRATE_VERSION="0.18.2"
}

dt_register "ctx_crate_cargo_deny" "cargo_deny" "$(cargo_install_methods)"

function _cargo_deny_opts() {
  _cargo_shared_manifest_opts
  if [ -z "${MESSAGE_FORMAT}" ]; then cmd+=(--format json); else cmd+=(--format "${MESSAGE_FORMAT}"); fi
  if [ -n "${DENY_REPORT}" ]; then cmd+=('2>' "${DENY_REPORT}"); fi
}

function cargo_deny() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  cd "${MANIFEST_DIR}"
  cmd=("$(dt_inline_envs "${_export_envs[@]}")")
  cmd+=(cargo deny)
  _cargo_deny_opts
  cmd+=(check)
  dt_exec ${fname} "${cmd[@]}"
}