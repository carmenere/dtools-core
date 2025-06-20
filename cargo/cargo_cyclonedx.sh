function ctx_crate_cargo_cyclonedx() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi
  var CRATE_NAME "cargo-cyclonedx"
  var CRATE_VERSION "0.5.7"
  ctx_cargo_crate && ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_crate_cargo_cyclonedx:cargo_cyclonedx:cargo_install_methods)

cyclonedx_msg_format() { if [ -n "$(MESSAGE_FORMAT)" ]; then echo "--format $(MESSAGE_FORMAT)"; fi; }

function cargo_cyclonedx() {
  exec_cmd cd "${DT_REPORTS}"
  exec_cmd $(cg_envs) cargo cyclonedx --all $(cg_manifest) $(cyclonedx_msg_format)
}