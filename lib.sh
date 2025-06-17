# All functions "error", "warning", "dt_info" and "debug" have the same signature:
#   $1: must contain $0 of caller
#   $2: must contain err message
function dt_error() {
  if [ "${DT_SEVERITY}" -ge 0 ]; then
    >&2 echo -e "${RED}${BOLD}[dtools][ERROR][$1]${RESET} $2"
  fi
}

function dt_warning() {
  if [ "${DT_SEVERITY}" -ge 1 ]; then
    >&2 echo -e "${CYAN}${BOLD}[dtools][WARNING][$1]${RESET} $2"
  fi
}

function dt_info() {
  if [ "${DT_SEVERITY}" -ge 2 ]; then
    >&2 echo -e "${GREEN}${BOLD}[dtools][INFO][$1]${RESET} $2"
  fi
}

function dt_debug () {
  if [ "${DT_SEVERITY}" -ge 3 ]; then
    >&2 echo -e "${MAGENTA}${BOLD}[dtools][DEBUG][$1]${RESET} $2"
  fi
}

function dryrun_off() { DT_DRYRUN="n"; }
function dryrun_on() { DT_DRYRUN="y"; }
function fname() { if [ -n "$1" ]; then echo "$1"; else echo "$2"; fi; }
function severity_debug() { DT_SEVERITY=3; }
function severity_error() { DT_SEVERITY=0; }
function severity_info() { DT_SEVERITY=2; }
function severity_warning() { DT_SEVERITY=1; }
function sleep_1() { cmd_exec "sleep 1"; }
function sleep_5() { cmd_exec "sleep 5"; }

function ser_val() {
  local val=$1
  if $(echo "${val}" | grep "'" >/dev/null 2>&1); then
    val="$(escape_quote "${val}")"
    val="$'${val}'"
  elif $(echo "${val}" | grep ' ' >/dev/null 2>&1); then
    val="\"${val}\""
  fi
  echo "${val}"
}

## Usage: load_vars ctx_service_pg_tetrix "FOO BAR"
function load_vars() {
  local ctx=$1 vars=($(echo $2)) fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx vars" || return $?
  . <(${ctx} || return $?
    for var in ${vars[@]}; do
      if ! declare -p ${var} >/dev/null 2>&1; then
        dt_error ${fname} "Variable ${BOLD}${var}${RESET} not found in ctx ${BOLD}${ctx}${RESET}"
        return 99
      fi
      val=$(eval echo "\${${var}}")
      val=$(ser_val "${val}")
      dt_debug ${fname} "${var}=${val}"
      echo "var ${var} ${val}"
    done)
}

function err_if_empty() {
  local var val fname=$1 vars=($(echo $2))
  if [ -z "${fname}" ]; then dt_error "err_if_empty" "Parameter ${BOLD}fname${RESET} must be provided"; return 55; fi
  if [ -z "${vars}" ]; then dt_error "err_if_empty" "Parameter ${BOLD}vars${RESET} must be provided"; return 55; fi
  for var in ${vars[@]}; do
    local val="$(eval echo "\$${var}")"
    if [ -z "${val}" ]; then
      dt_error ${fname} "Parameter ${BOLD}${var}${RESET} is empty"
      return 77
    fi
  done
}

function inline_vals() {
  local pref vals result val fname=$(fname "${FUNCNAME[0]}" "$0")
  vals=($(echo "$1"))
  [ -n "$2" ] && pref="$2 "
  result=()
  for val in ${vals[@]}; do
    val=$(ser_val "${val}")
    result+=("${pref}${val}")
  done
  echo "${result[@]}"
}

function inline_vars() {
  local pref result var val vars=($(echo "$1")) fname=$(fname "${FUNCNAME[0]}" "$0")
  [ -n "$2" ] && pref="$2 "
  result=()
  for var in ${vars[@]}; do
    val="$(eval echo \$${var})"
    dt_debug ${fname} "var=${var}; val=${val}"
    if [ -z "${val}" ]; then continue; fi
    val=$(ser_val "${val}")
    result+=("${pref}${var}=${val}")
  done
  echo "${result[@]}"
}

function escape_quote() {
  echo "$1" | sed -e "s/'/\\\\'/g"
}

function dt_rc_load() {
  description=$1
  dir=$2
  if [ -z "${description}" ]; then return 99; fi
  if [ -z "${dir}" ]; then return 99; fi
  echo -e "Loading ${BOLD}$description${RESET} ... "
  for file in "$dir"/*.sh; do
    if [ "$(basename "$file")" != "rc.sh"  ]; then
      echo -e -n "Sourcing "$(dirname "$file")/${BOLD}$(basename "$file")${RESET}" ..."
      . "$file" || return 55
      echo "done.";
    fi
  done
}

function cmd_exec () {
  local cmd fname=$(fname "${FUNCNAME[0]}" "$0")
  cmd=$(echo "$@" | sed 's/^[ \t]*//')
  if [ -z "${cmd}" ]; then
    dt_error ${fname} "The command is empty cmd='${cmd}'."
    return 99
  fi
  if [ "${DT_DRYRUN}" = "y" ]; then
    if [ "${DT_ECHO}" = "y" ]; then
      >&2 echo -e "${BOLD}[dtools][DT_DRYRUN]${RESET}"
      >&2 echo -e "${cmd}"
    fi
    if [ "${DT_ECHO_STDOUT}" = "y" ]; then
      echo -e "${cmd}"
    fi
  else
    if [ "${DT_ECHO}" = "y" ]; then
      >&2 echo -e "${BOLD}${DT_ECHO_COLOR}[dtools][DT_ECHO][cmd_exec]${RESET}"
      >&2 echo -e "${DT_ECHO_COLOR}${cmd}${RESET}"
    fi
    eval "${cmd}" || return $?
  fi
}

function var() {
  local fname var val fname=$(fname "${FUNCNAME[0]}" "$0")
  var=$1; err_if_empty ${fname} "var" || return $?
  if declare -p ${var} >/dev/null 2>&1; then return 0; fi
  val=$(ser_val "$2")
  dt_debug ${fname} "Setting var ${BOLD}${var}${RESET} to val ${val}"
  eval "${var}=${val}"
  DT_VARS+=(${var})
}

function vars() {
  local fname ctx=$1 val fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${ctx}" ]; then
    if ! declare -f ${ctx} >/dev/null 2>&1; then
      dt_error ${fname} "Context ${BOLD}${ctx}${RESET} doesn't exist."
      return 99
    fi
    (
      unset_vars 1>/dev/null 2>&1
      ${ctx} 1>/dev/null 2>&1
      for var in ${DT_VARS[@]}; do
        val=$(eval echo "\${${var}}")
        echo -e "${BOLD}${var}${RESET}='${val}'"
      done
    )
  else
    for var in ${DT_VARS[@]}; do
      val=$(eval echo "\${${var}}")
      echo -e  "${BOLD}${var}${RESET}='${val}'"
    done
  fi
}

function unset_vars() {
  for var in ${DT_VARS[@]}; do
    val=$(eval echo "\${${var}}")
    cmd_exec "unset ${var}"
  done
  DT_VARS=()
}

## Consider function docker_build(), then the call "dt_register ctx_docker_pg_admin pg docker_methods"
## will generate function docker_build_pg() { dt_init_and_load_ctx && docker_build_pg }
function dt_bind() {
  local ctx suffix methods method fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx=$(echo "$1" | cut -d':' -f 1)
  suffix=$(echo "$1" | cut -d':' -f 2)
  methods=$(echo "$1" | cut -d':' -f 3)
  err_if_empty ${fname} "ctx suffix methods" || return $?
  if [ -n "${suffix}" ]; then suffix="_${suffix}"; fi
  methods=($(echo $(${methods})| sort))
  for method in ${methods[@]}; do
    DT_REGISTERED_METHODS+=(${method}${suffix})
    if declare -f "${method}${suffix}" >/dev/null 2>&1; then
      dt_info ${fname} "Function ${BOLD}${method}${suffix}${RESET} has already registered"
      continue
    fi
    dt_debug ${fname} "Register method: ${BOLD}${method}${suffix}${RESET}() {( ${ctx} && ${method}; )}"
    eval "function ${method}${suffix}() {( ${ctx} && ${method}; )}" || return $?
  done
}

function get_method() {
  local m method=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "${method}" ]; then dt_error ${fname} "Method was not provided"; return 99; fi
  for m in ${DT_BIND_EXCEPTIONS[@]};  do
    if [ "$m" = "${method}" ]; then
      dt_debug ${fname} "HIT: ${BOLD}Method${RESET}=${m}"
      return 0
    fi
  done
}

dt_unregister() {
  local method fname=$(fname "${FUNCNAME[0]}" "$0")
  for method in ${DT_REGISTERED_METHODS[@]}; do
    if declare -f "${method}" >/dev/null 2>&1; then
      dt_debug ${fname} "unset -f ${method}"
      unset -f ${method}
    fi
  done
  export DT_REGISTERED_METHODS=()
}

dt_register() {
  local binding fname=$(fname "${FUNCNAME[0]}" "$0")
  for binding in ${DT_BINDINGS[@]}; do dt_bind "${binding}"; done
}

dt_bindings() {
  local binding fname=$(fname "${FUNCNAME[0]}" "$0")
  DT_BINDINGS=($(for binding in ${DT_BINDINGS[@]}; do echo "${binding}"; done | sort))
  for binding in ${DT_BINDINGS[@]}; do echo "${binding}"; done
}

dt_registered_methods() {
  local method fname=$(fname "${FUNCNAME[0]}" "$0")
  DT_REGISTERED_METHODS=($(for method in ${DT_REGISTERED_METHODS[@]}; do echo "${method}"; done | sort))
  for method in ${DT_REGISTERED_METHODS[@]}; do echo "${method}"; done
}

function cmd_echo() {
  local saved_DRYRUN saved_ECHO fname=$(fname "${FUNCNAME[0]}" "$0")
  saved_DRYRUN=${DT_DRYRUN}
  saved_ECHO=${DT_DRYRUN}
  dryrun_on
  DT_ECHO_STDOUT="y"
  DT_ECHO="n"
  $@ || return $?
  DT_ECHO_STDOUT="n"
  DT_DRYRUN=${saved_DRYRUN}
  DT_ECHO=${saved_ECHO}
}

function paths() {
  if [ -z "${DTOOLS}" ]; then DTOOLS="$(pwd)"; fi
  # Paths that depend on DTOOLS
  export DT_PROJECT=$(realpath "${DTOOLS}"/..)
  export DT_ARTEFACTS="${DTOOLS}/.artefacts"
  export DT_CORE=${DTOOLS}/core
  export DT_LOCALS=${DTOOLS}/locals
  export DT_STANDS=${DTOOLS}/stands
  export DT_TOOLS=${DTOOLS}/tools
  # Paths that depend on DT_ARTEFACTS
  export DT_LOGS="${DT_ARTEFACTS}/logs"
  export DT_REPORTS="${DT_ARTEFACTS}/reports"
  export DT_TOOLCHAIN=${DT_ARTEFACTS}/toolchain
  # Cache for ctxes
  export CTXES=${DT_LOGS}/ctxes
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  if [ ! -d "${DT_REPORTS}" ]; then mkdir -p ${DT_REPORTS}; fi
  if [ ! -d "${DT_TOOLCHAIN}" ]; then mkdir -p ${DT_TOOLCHAIN}; fi
  # Delete all ctxes every time ". ./dtools/rc.sh" is called
  rm -rf ${CTXES} && mkdir -p ${CTXES}
}

# DT_SEVERITY >= 4 for dumps!
function defaults() {
  export DT_DRYRUN="n"
  export DT_SEVERITY=4
  export DT_ECHO="y"
  export DT_ECHO_STDOUT="n"
  export DT_ECHO_COLOR="${YELLOW}"
  export DT_BINDINGS=()
  export PROFILE_CI=
  unset_vars && export DT_VARS
}

function dt_init() {
  paths || return $?
  . "${DT_CORE}/colors.sh"
  defaults && \
  dt_unregister || return $?
  . "${DT_CORE}/rc.sh"
  . "${DT_TOOLS}/rc.sh"
  . "${DT_STANDS}/rc.sh"
  if [ -f "${DT_LOCALS}/rc.sh" ]; then . "${DT_LOCALS}/rc.sh"; fi
  dt_register
}