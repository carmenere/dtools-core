cyclonedx_msg_format() { if [ -n "${MESSAGE_FORMAT}" ]; then echo "--format ${MESSAGE_FORMAT}"; fi; }

function cargo_audit() {(
  set -eu
  . "${DT_VARS}/cargo/ssdlc/$1.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo audit --${MESSAGE_FORMAT} '>' "${AUDIT_REPORT}"
)}

function cargo_cyclonedx() {(
  set -eu
  . "${DT_VARS}/cargo/ssdlc/$1.sh"
  exec_cmd cd "${DT_REPORTS}"
  exec_cmd "$(inline_envs)" cargo cyclonedx --all $(cg_manifest) $(cyclonedx_msg_format)
)}

function cargo_deny() {(
  set -eu
  . "${DT_VARS}/cargo/ssdlc/$1.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo deny $(cyclonedx_msg_format) '2>' "${DENY_REPORT} check"
)}

function cargo_sonar() {(
  set -eu
  . "${DT_VARS}/cargo/ssdlc/$1.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo sonar --clippy-path "${CLIPPY_REPORT}" --audit-path "${AUDIT_REPORT}" \
      --deny-path "${DENY_REPORT}" --sonar-path "${SONAR_REPORT}"
)}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_cargo_ssdlc() {
  local methods=()
  methods+=(cargo_audit)
  methods+=(cargo_cyclonedx)
  methods+=(cargo_deny)
  methods+=(cargo_sonar)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_cargo_ssdlc"