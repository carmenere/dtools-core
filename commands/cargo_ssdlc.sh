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
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo cyclonedx --all $(cyclonedx_msg_format)
  exec_cmd "find ${MANIFEST_DIR} -regex '.*\.cdx\.json' | xargs -L 1 -I{} mv {} ${SSDLC_CDX_REPORTS}"
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

cargo_clippy_ssdlc() {(
  set -eu
  . "${DT_VARS}/cargo/ssdlc/$1.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo clippy $(cg_targets) $(cg_features) $(cg_profile) $(cg_msg_format) \
    -- $(cg_clippy_lints) $(cg_clippy_report)
)}

cargo_ssdlc() {(
  set -eu
  cargo_clippy_ssdlc $1 || true
  cargo_audit $1 || true
  cargo_cyclonedx $1 || true
  cargo_deny $1 || true
  cargo_sonar $1 || true
)}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_cargo_ssdlc() {
  local methods=()
  methods+=(cargo_audit)
  methods+=(cargo_cyclonedx)
  methods+=(cargo_deny)
  methods+=(cargo_sonar)
  methods+=(cargo_clippy_ssdlc)
  methods+=(cargo_ssdlc)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_cargo_ssdlc"