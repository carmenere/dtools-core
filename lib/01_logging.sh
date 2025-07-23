rst_err_cnt() { ERR_COUNTER=0; }
inc_err_cnt() { ERR_COUNTER=$((${ERR_COUNTER}+1)); }
get_err_cnt() { echo ${ERR_COUNTER}; }

# All functions "error", "warning", "dt_info" and "debug" have the same signature:
#   $1: must contain $0 of caller
#   $2: must contain err message
dt_error() {
  inc_err_cnt
  if [ "${DT_SEVERITY}" -ge 1 ]; then
    >&2 echo -e "${RED}${BOLD}[dtools][ERROR][$1]${RESET} $2"
  fi
}

dt_warning() {
  if [ "${DT_SEVERITY}" -ge 2 ]; then
    >&2 echo -e "${CYAN}${BOLD}[dtools][WARNING][$1]${RESET} $2"
  fi
}

dt_info() {
  if [ "${DT_SEVERITY}" -ge 3 ]; then
    >&2 echo -e "${GREEN}${BOLD}[dtools][INFO][$1]${RESET} $2"
  fi
}

dt_debug () {
  if [ "${DT_SEVERITY}" -ge 4 ]; then
    >&2 echo -e "${MAGENTA}${BOLD}[dtools][DEBUG][$1]${RESET} $2"
  fi
}

dt_log() {
  >&2 echo -e "${BOLD}[dtools][LOG][$1]${RESET} $2"
}

set_severity_error() { local fname=$(fname "${FUNCNAME[0]}" "$0"); DT_SEVERITY=1; dt_log ${fname} "DT_SEVERITY=${DT_SEVERITY}"; }
set_severity_warning() { local fname=$(fname "${FUNCNAME[0]}" "$0"); DT_SEVERITY=2; dt_log ${fname} "DT_SEVERITY=${DT_SEVERITY}"; }
set_severity_info() { local fname=$(fname "${FUNCNAME[0]}" "$0"); DT_SEVERITY=3; dt_log ${fname} "DT_SEVERITY=${DT_SEVERITY}"; }
set_severity_debug() { local fname=$(fname "${FUNCNAME[0]}" "$0"); DT_SEVERITY=4; dt_log ${fname} "DT_SEVERITY=${DT_SEVERITY}"; }

severity() { echo "${DT_SEVERITY}"; }

err_if_empty() {
  local var vars val fname=$1 vars=($(echo $2))
  if [ -z "${fname}" ]; then dt_error "err_if_empty in ${fname}" "Parameter ${BOLD}fname${RESET} must be provided"; return 55; fi
  if [ -z "${vars}" ]; then dt_error "err_if_empty in ${fname}" "Parameter ${BOLD}vars${RESET} must be provided"; return 55; fi
  for var in ${vars[@]}; do
    val="$(eval echo "\$${var}")"
    if [ -z "${val}" ]; then
      dt_error "err_if_empty in ${fname}" "Parameter ${BOLD}${var}${RESET} is empty"
      return 77
    fi
  done
}
