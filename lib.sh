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
    val=$(${var})
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

function is_contained() {
  local item=$1 registry=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "item registry" || return $?
  registry=($(echo $(eval echo \$${registry})))
  for ritem in ${registry[@]};  do
    if [ "${ritem}" = "${item}" ]; then
      dt_debug ${fname} "HIT: ${BOLD}Item${RESET}=${item}"
      return 0
    fi
  done
  return 88
}

function var_pref() {
  local ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${ctx}" ]; then
    echo "${ctx}__"
  fi
}

function is_cached() {
  local ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx" || return $?
  if declare -p cache__${ctx} >/dev/null 2>&1 && [ "${DT_CTX}" = "${ctx}" ]; then
    dt_debug ${fname} "Context ${BOLD}${ctx}${RESET} has already initialized."
    DT_CTX=
    return 0
  else
    return $?
  fi
}

ctx_prolog(){
  local ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx" || return $?
  if [ -z "${DT_CTX}" ]; then DT_CTX=${ctx}; fi
  if ! is_contained ${ctx} DT_CTXES; then DT_CTXES+=(${ctx}); fi
  dt_debug ${fname} "DT_CTX=${BOLD}${DT_CTX}${RESET}, current ctx is ${BOLD}${ctx}${RESET}"
}


# Consistent behaviour in zsh and bash: ${array[@]:offset:length}
ctx_epilog(){
  local ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx" || return $?
  if [ "${DT_CTX}" = "${ctx}" ]; then
    export cache__${ctx}
    dt_debug ${fname} "Adding ctx=${BOLD}${ctx}${RESET} to cache, DT_CTX=${DT_CTX}"
    DT_CTX=
  fi
}

function switch_ctx() {
  local ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx" || return $?
  DT_CTX=
  ${ctx} || return $?
  DT_CTX=${ctx}
}

function get_var() {
  local val var=$1 ctx=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "${ctx}" ]; then
    if [ -z "${DT_CTX}" ]; then
      dt_error ${fname} "Global variable ${BOLD}DT_CTX${RESET} is not set"
      return 99
    fi
    ctx=${DT_CTX}
  fi
  var=$(var_pref ${ctx})${var} || return $?
  if declare -p ${var} >/dev/null 2>&1; then
    val=$(eval echo \$${var})
    echo "${val}"
  else
    dt_error ${fname} "Variable ${BOLD}${var}${RESET} doesn't exist"
  fi
}

# sets var in some ctx
function var() {
  local val ovar var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "var" || return $?
  dt_debug ${fname} "var=${var}"
  ovar=${var}
  if [ -z "${DT_CTX}" ]; then
    dt_error ${fname} "Global variable ${BOLD}DT_CTX${RESET} is not set"
    return 99
  fi
  var=$(var_pref ${DT_CTX})${var} || return $?
  if declare -p ${var} >/dev/null 2>&1; then return 0; fi
  val=$(ser_val "$2")
  dt_debug ${fname} "Setting var ${BOLD}${var}${RESET} to val ${BOLD}${val}${RESET}"
  eval "export ${var}=${val}"
  DT_VARS+=(${var})
  eval "${ovar}() { get_var ${ovar} \$1}"
}

function drop_ctx() {
  local pref ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx" || return $?
  dt_debug ${fname} "${ctx}"
  pref=$(var_pref ${ctx})
  . <(env | while read var; do
    awk -v pref="${pref}" -F'=' '{ if ($1 ~ pref) { printf "unset %s\n", $1; } }'
  done)
  unset "cache__${ctx}"
}

function drop_all_ctxes() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "*"
  for ctx in ${DT_CTXES[@]}; do
    unset "cache__${ctx}"
  done
  for var in ${DT_VARS[@]}; do
    unset ${var}
  done
}

function load_vars() {
  local var dt_ctx ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift
  if ! declare -f ${ctx} >/dev/null 2>&1; then
    dt_error ${fname} "Context ${BOLD}${ctx}${RESET} doesn't exist"
    return 99
  fi
  dt_ctx=${DT_CTX}; DT_CTX=
  ${ctx}
  DT_CTX=${dt_ctx}
  for var in $@; do
    if ! declare -f ${var} >/dev/null 2>&1; then
      dt_error ${fname} "Variable ${BOLD}${var}${RESET} has not registered yet"
      return 99
    fi
    if ! declare -p $(var_pref ${ctx})${var} >/dev/null 2>&1; then
      dt_error ${fname} "Variable ${BOLD}${var}${RESET} doesn't exist in ctx=${BOLD}${ctx}${RESET}"
      return 99
    fi
    var ${var} $(${var} ${ctx})
  done
}

## Consider function docker_build(), then the call "dt_register ctx_docker_pg_admin pg docker_methods"
## will generate function docker_build_pg() { dt_init_and_load_ctx && docker_build_pg }
function dt_bind() {
  local ctx suffix methods method excluded fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx=$(echo "$1" | cut -d':' -f 1)
  suffix=$(echo "$1" | cut -d':' -f 2)
  methods=$(echo "$1" | cut -d':' -f 3)
  excluded=$(echo "$1" | cut -d':' -f 4)
  err_if_empty ${fname} "ctx suffix methods" || return $?
  if [ -n "${suffix}" ]; then suffix="_${suffix}"; fi
  methods=($(echo $(${methods})| sort))
  excluded=($(echo ${excluded}))
  dt_debug ${fname} "excluded=${excluded[@]}"
  for method in ${methods[@]}; do
    if is_contained ${method}${suffix} excluded; then continue; fi
    if is_contained ${method}${suffix} DT_METHODS; then continue; else DT_METHODS+=(${method}${suffix}); fi
    dt_debug ${fname} "Register method: ${BOLD}${method}${suffix}${RESET}() {( ${ctx} && ${method}; )}"
    eval "function ${method}${suffix}() { switch_ctx ${ctx} && ${method}; }" || return $?
  done
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

dt_methods() {
  local method fname=$(fname "${FUNCNAME[0]}" "$0")
  DT_METHODS=($(for method in ${DT_METHODS[@]}; do echo "${method}"; done | sort))
  for method in ${DT_METHODS[@]}; do echo "${method}"; done
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

function dt_paths() {
  if [ -z "${DTOOLS}" ]; then DTOOLS=$(realpath $(dirname "$(realpath $self)")/..); fi
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
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  if [ ! -d "${DT_REPORTS}" ]; then mkdir -p ${DT_REPORTS}; fi
  if [ ! -d "${DT_TOOLCHAIN}" ]; then mkdir -p ${DT_TOOLCHAIN}; fi
}

# DT_SEVERITY >= 4 for dumps!
function dt_defaults() {
  drop_all_ctxes || return $?
  export DT_BINDINGS=()
  export DT_CTX=
  export DT_CTXES=()
  export DT_DRYRUN="n"
  export DT_ECHO="y"
  export DT_ECHO_COLOR="${YELLOW}"
  export DT_ECHO_STDOUT="n"
  export DT_METHODS=()
  export DT_SEVERITY=4
  export DT_VARS=()
  export PROFILE_CI=
}
