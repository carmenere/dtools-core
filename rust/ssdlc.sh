function cargo_ssdlc_reports() {
  CLIPPY_REPORT="${DT_REPORTS}/clippy-report.json"
  AUDIT_REPORT="${DT_REPORTS}/audit-report.json"
  DENY_REPORT="${DT_REPORTS}/deny-report.json"
  SONAR_REPORT="${DT_REPORTS}/sonar-report.json"
  MESSAGE_FORMAT=json
}

cargo_ssdlc_methods=()

cargo_ssdlc_methods+=(cargo_audit)
cargo_ssdlc_methods+=(cargo_deny)
cargo_ssdlc_methods+=(cargo_sonar)
cargo_ssdlc_methods+=(cargo_cyclonedx)
cargo_ssdlc_methods+=(cargo_clippy)

function impl_cargo_ssdlc() {
  local ctx=$1; dt_err_if_empty $0 "ctx"; exit_on_err $0 $? || return $?
  local suffix=$2; dt_err_if_empty $0 "suffix"; exit_on_err $0 $? || return $?
  dt_impl "${ctx}" "${suffix}" "${cargo_ssdlc_methods[@]}"; exit_on_err $0 $? || return $?
}