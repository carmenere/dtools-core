. ${DT_VARS}/cargo/package/tetrix.sh

CLIPPY_REPORT="${DT_REPORTS}/clippy-report.json"
AUDIT_REPORT="${DT_REPORTS}/audit-report.json"
DENY_REPORT="${DT_REPORTS}/deny-report.json"
SONAR_REPORT="${DT_REPORTS}/sonar-report.json"
MESSAGE_FORMAT="json"

LOCALS=${DT_LOCAL_VARS}/cargo/ssdlc/tetrix.sh
source_locals ${LOCALS}