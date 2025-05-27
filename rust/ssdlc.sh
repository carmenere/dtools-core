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
