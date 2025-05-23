function ctx_crate_cargo_audit() {
  ctx_rustup
  CRATE_NAME="cargo-audit"
  CRATE_VERSION="0.21.2"
  FORCE=
  FROZEN=
  IGNORE_RUST_VERSION=
  LOCKED="y"
  OFFLINE=
}
function cargo_install_cargo_audit() { cargo_install ctx_crate_cargo_audit }
function cargo_uninstall_cargo_audit() { cargo_uninstall ctx_crate_cargo_audit }

function ctx_crate_cargo_deny() {
  ctx_crate_cargo_audit
  CRATE_NAME="cargo-deny"
  CRATE_VERSION="0.18.2"
}
function cargo_install_cargo_deny() { cargo_install ctx_crate_cargo_deny }
function cargo_uninstall_cargo_deny() { cargo_uninstall ctx_crate_cargo_deny }

function ctx_crate_cargo_sonar() {
  ctx_crate_cargo_audit
  CRATE_NAME="cargo-sonar"
  CRATE_VERSION="1.3.0"
}
function cargo_install_cargo_sonar() { cargo_install ctx_crate_cargo_sonar }
function cargo_uninstall_cargo_sonar() { cargo_uninstall ctx_crate_cargo_sonar }

function ctx_crate_cargo_cyclonedx() {
  ctx_crate_cargo_audit
  CRATE_NAME="cargo-cyclonedx"
  CRATE_VERSION="0.5.7"
}
function cargo_install_cargo_cyclonedx() { cargo_install ctx_crate_cargo_cyclonedx }
function cargo_uninstall_cargo_cyclonedx() { cargo_uninstall ctx_crate_cargo_cyclonedx }

function cargo_audit_opts() {
  cargo_shared_manifest_opts
  if [ -z "${MESSAGE_FORMAT}" ]; then cmd+=(--json); else cmd+=(--"${MESSAGE_FORMAT}"); fi
  if [ -n "${AUDIT_REPORT}" ]; then cmd+=('>' "${AUDIT_REPORT}"); fi
}

function cargo_deny_opts() {
  cargo_shared_manifest_opts
  if [ -z "${MESSAGE_FORMAT}" ]; then cmd+=(--format json); else cmd+=(--format "${MESSAGE_FORMAT}"); fi
  if [ -n "${DENY_REPORT}" ]; then cmd+=('2>' "${DENY_REPORT}"); fi
}

function cargo_sonar_opts() {
  cargo_shared_manifest_opts
  if [ -n "${CLIPPY_REPORT}" ]; then cmd+=(--clippy-path "${CLIPPY_REPORT}"); fi
  if [ -n "${AUDIT_REPORT}" ]; then cmd+=(--audit-path "${AUDIT_REPORT}"); fi
  if [ -n "${DENY_REPORT}" ]; then cmd+=(--deny-path "${DENY_REPORT}"); fi
  if [ -n "${SONAR_REPORT}" ]; then cmd+=(--sonar-path "${SONAR_REPORT}"); fi
}

function cargo_cyclonedx_opts() {
  cargo_shared_manifest_opts
  if [ -n "${MANIFEST_PATH}" ]; then cmd+=(--manifest-path "${MANIFEST_PATH}"); fi
  if [ -z "${MESSAGE_FORMAT}" ]; then cmd+=(--format json); else cmd+=(--format "${MESSAGE_FORMAT}"); fi
}

function cargo_audit() {
  cd "${MANIFEST_DIR}"
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo audit)
  cargo_audit_opts
  dt_exec_or_echo "${cmd} || true" $mode
}

function cargo_deny() {
  cd "${MANIFEST_DIR}"
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo deny)
  cargo_deny_opts
  cmd+=(check)
  dt_exec_or_echo "${cmd} || true" $mode
}

function cargo_sonar() {
  cd "${MANIFEST_DIR}"
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo sonar)
  cargo_sonar_opts
  dt_exec_or_echo "${cmd}" $mode
}

function cargo_cyclonedx() {
  cd "${DT_REPORTS}"
  cmd=("$(dt_inline_envs)")
  cmd+=(cargo cyclonedx --all)
  cargo_cyclonedx_opts
  dt_exec_or_echo "${cmd}" $mode
}
