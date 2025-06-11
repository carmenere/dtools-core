function ctx_crate_cargo_cyclonedx() {
  ctx_crate_defaults
  CRATE_NAME="cargo-cyclonedx"
  CRATE_VERSION="0.5.7"
}

dt_register "ctx_crate_cargo_cyclonedx" "cargo_cyclonedx" "$(cargo_install_methods)"

function _cargo_cyclonedx_opts() {
  _cargo_shared_manifest_opts
  if [ -n "${MANIFEST_PATH}" ]; then cmd+=(--manifest-path "${MANIFEST_PATH}"); fi
  if [ -z "${MESSAGE_FORMAT}" ]; then cmd+=(--format json); else cmd+=(--format "${MESSAGE_FORMAT}"); fi
}

function cargo_cyclonedx() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  cd "${DT_REPORTS}"
  cmd=("$(dt_inline_envs "${_export_envs[@]}")")
  cmd+=(cargo cyclonedx --all)
  _cargo_cyclonedx_opts
  dt_exec ${fname} "${cmd[@]}"
}
