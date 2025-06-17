function ctx_crate_cargo_cyclonedx() {
  ctx_cargo_crate || return $?
  CRATE_NAME="cargo-cyclonedx"
  CRATE_VERSION="0.5.7"
}

DT_BINDINGS+=(ctx_crate_cargo_cyclonedx:cargo_cyclonedx:cargo_install_methods)

cyclonedx_msg_format() { if [ -n "${MESSAGE_FORMAT}" ]; then echo "--format ${MESSAGE_FORMAT}"; fi; }

function cargo_cyclonedx() {
  cmd_exec cd "${DT_REPORTS}"
  cmd_exec $(cg_envs) cargo cyclonedx --all $(cg_manifest) $(cyclonedx_msg_format)
}