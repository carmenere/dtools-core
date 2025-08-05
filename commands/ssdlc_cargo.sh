

function ctx_cargo_ssdlc() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var CLIPPY_REPORT "${DT_REPORTS}/clippy-report.json" && \
  var AUDIT_REPORT "${DT_REPORTS}/audit-report.json" && \
  var DENY_REPORT "${DT_REPORTS}/deny-report.json" && \
  var SONAR_REPORT "${DT_REPORTS}/sonar-report.json" && \
  var MESSAGE_FORMAT "json" && \
  cache_ctx
}



##################################################### AUTOCOMPLETE #####################################################
function cmd_family_cargo_ssdlc() {
  local methods=()
  methods+=(cargo_audit)
  methods+=(cargo_clippy)
  methods+=(cargo_cyclonedx)
  methods+=(cargo_deny)
  methods+=(cargo_sonar)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_cargo_ssdlc"