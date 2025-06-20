# All functions "error", "warning", "dt_info" and "debug" have the same signature:
#   $1: must contain $0 of caller
#   $2: must contain err message
dt_error() {
  if [ "${DT_SEVERITY}" -ge 0 ]; then
    >&2 echo -e "${RED}${BOLD}[dtools][ERROR][$1]${RESET} $2"
  fi
}

dt_warning() {
  if [ "${DT_SEVERITY}" -ge 1 ]; then
    >&2 echo -e "${CYAN}${BOLD}[dtools][WARNING][$1]${RESET} $2"
  fi
}

dt_info() {
  if [ "${DT_SEVERITY}" -ge 2 ]; then
    >&2 echo -e "${GREEN}${BOLD}[dtools][INFO][$1]${RESET} $2"
  fi
}

dt_debug () {
  if [ "${DT_SEVERITY}" -ge 3 ]; then
    >&2 echo -e "${MAGENTA}${BOLD}[dtools][DEBUG][$1]${RESET} $2"
  fi
}

fname() { if [ -n "$1" ]; then echo "$1"; else echo "$2"; fi; }
severity_debug() { DT_SEVERITY=3; }
severity_error() { DT_SEVERITY=0; }
severity_info() { DT_SEVERITY=2; }
severity_warning() { DT_SEVERITY=1; }
sleep_1() { exec_cmd "sleep 1"; }
sleep_5() { exec_cmd "sleep 5"; }

ser_val() {
  local val=$1
  if $(echo "${val}" | grep "'" >/dev/null 2>&1); then
    val="$(escape_quote "${val}")"
    val="$'${val}'"
  elif $(echo "${val}" | grep ' ' >/dev/null 2>&1); then
    val="\"${val}\""
  fi
  echo "${val}"
}

err_if_empty() {
  local var vars val fname=$1 vars=($(echo $2))
  if [ -z "${fname}" ]; then dt_error "err_if_empty" "Parameter ${BOLD}fname${RESET} must be provided"; return 55; fi
  if [ -z "${vars}" ]; then dt_error "err_if_empty" "Parameter ${BOLD}vars${RESET} must be provided"; return 55; fi
  for var in ${vars[@]}; do
    val="$(eval echo "\$${var}")"
    if [ -z "${val}" ]; then
      dt_error ${fname} "Parameter ${BOLD}${var}${RESET} is empty"
      return 77
    fi
  done
}

inline_vals() {
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

inline_vars() {
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

escape_quote() {
  echo "$@" | sed -e "s/'/\\\\'/g"
}

escape_dollar() {
  echo "$@" | sed -e "s/\\$/\\\\$/g" | sed -e "s/'/\\\\'/g"
}

is_contained() {
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

var_pref() {
  local ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${ctx}" ]; then
    echo "${ctx}__"
  fi
}

is_cached() {
  local ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx" || return $?
  if [ -z "${DT_START_CTX}" ] && declare -p cache__${ctx} >/dev/null 2>&1; then
    dt_debug ${fname} "${BOLD}${ctx}${RESET} is cached"
    return 0
  else
    return 99
  fi
}

ctx_prolog() {
  local ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx" || return $?
  if [ -z "${DT_START_CTX}" ] && ! declare -p cache__${ctx} >/dev/null 2>&1; then
    dt_debug ${fname} "DT_START_CTX is empty"
    DT_START_CTX=${ctx}
    push_ctx ${ctx}
    dt_debug ${fname} "Starting from DT_START_CTX=${BOLD}${DT_START_CTX}${RESET}"
  else
    if [ "${DT_START_CTX}" != "${ctx}" ]; then
      dt_debug ${fname} "DT_START_CTX=${BOLD}${DT_START_CTX}${RESET} is is being merged with ctx=${BOLD}${ctx}${RESET}"
    fi
  fi
}

# Consistent behaviour in zsh and bash: ${array[@]:offset:length}
ctx_epilog(){
  local var ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx" && \
  dt_debug ${fname} "DT_START_CTX=${BOLD}${DT_START_CTX}${RESET}, current is ${BOLD}${ctx}${RESET}" && \
  if [ "${DT_START_CTX}" = "${ctx}" ]; then
    var="cache__${ctx}" && \
    if ! declare -p ${var} >/dev/null 2>&1; then
      dt_debug ${fname} "Caching ctx=${BOLD}${ctx}${RESET}" && \
      eval "${var}=1" && \
      DT_VARS+=(${var}) && \
      DT_CTXES+=(${ctx})
    fi
    pop_ctx && \
    DT_START_CTX=
  fi
  dt_debug ${fname} "DT_START_CTX=${BOLD}${DT_START_CTX}${RESET}"
}

push_ctx() {
  local dt_ctx_stack ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx" && \
  dt_debug ${fname} "Pushing ctx ${CYAN}${BOLD}'${ctx}'${RESET}" && \
  DT_CTX_STACK+=(${ctx}) && \
  dt_ctx_stack="${DT_CTX_STACK[@]}" && \
  dt_debug ${fname} "DT_CTX_STACK=${CYAN}${BOLD}( ${dt_ctx_stack} )${RESET}, N=${#DT_CTX_STACK[@]}" && \
  dt_debug ${fname} "Init ctx ${CYAN}${BOLD}${ctx}${RESET}" && \
  ${ctx} && \
  dt_debug ${fname} "${CYAN}${BOLD}Inited${RESET}"
}

pop_ctx() {
  local i N=$1 fname=$(fname "${FUNCNAME[0]}" "$0") && \
  if [ -z "$1" ]; then N=1; else N=$1; fi && \
  dt_debug ${fname} "Popping ${CYAN}${BOLD}N=${N}${RESET} ctxes ... " && \
  for ((i = 0; i < N; ++i)); do
    pop_one_ctx || return $?
  done
  dt_debug ${fname} "${CYAN}${BOLD}done${RESET}"
}

pop_one_ctx() {
  local dt_ctx_stack fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "${#DT_CTX_STACK[@]}" -gt 0 ]; then
    dt_debug ${fname} "Popping ctx ${CYAN}${BOLD}${DT_CTX_STACK[-1]}${RESET}" && \
    unset 'DT_CTX_STACK[-1]' && \
    DT_CTX_STACK=($(echo "${DT_CTX_STACK[@]}")) && \
    dt_ctx_stack="${DT_CTX_STACK[@]}" && \
    dt_debug ${fname} "DT_CTX_STACK=${CYAN}${BOLD}( ${dt_ctx_stack} )${RESET}, N=${#DT_CTX_STACK[@]}"
  else
    dt_debug ${fname} "${CYAN}${BOLD}DT_CTX_STACK${RESET} is empty, nothing to pop"
  fi
}

# get value of var in some ctx
# ovar: original var
# octx: original ctx
get_var() {
  local val octx ctx var ovar=$1 octx=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${octx}" ]; then ctx="${octx}"; else ctx="${DT_CTX_STACK[-1]}"; fi
  if [ -z "${ctx}" ]; then
    dt_error ${fname} "Context for variable ${BOLD}${var}${RESET} was not provided: ${BOLD}DT_CTX_STACK${RESET} is empty and ${BOLD}octx${RESET} is empty"
    return 99
  fi
  var=$(var_pref ${ctx})${ovar} || return $?
  if declare -p ${var} >/dev/null 2>&1; then
    val=$(eval echo \$${var})
    echo "${val}"
  else
    dt_error ${fname} "Variable ${BOLD}${var}${RESET} doesn't exist"
  fi
}

# sets or resets var in some ctx
# ovar: original var
# octx: original ctx
var() {
  local val ovar octx fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "$1" = "-r" ]; then mode="reset"; shift; else mode="set"; fi
  ovar=$1; val=$2 octx=$3
  err_if_empty ${fname} "ovar" || return $?
  if [ -n "${octx}" ]; then ctx="${octx}"; else ctx="${DT_CTX_STACK[-1]}"; fi
  if [ -z "${ctx}" ]; then
    dt_error ${fname} "Context for variable ${BOLD}${var}${RESET} was not provided: ${BOLD}DT_CTX_STACK${RESET} is empty and ${BOLD}octx${RESET} is empty"
    return 99
  fi
  var=$(var_pref ${ctx})${ovar} || return $?
  if declare -p ${var} >/dev/null 2>&1 && [ "${mode}" != "reset" ]; then return 0; fi
  val=$(ser_val "${val}")
  dt_debug ${fname} "Setting var ${BOLD}${var}${RESET} to val ${BOLD}${val}${RESET}, mode=${mode}"
  eval "${var}=${val}"
  if ! is_contained ${var} DT_VARS; then DT_VARS+=(${var}); fi
  eval "${ovar}() { get_var ${ovar} \$1; }"
}

drop_vars_by_pref() {
  local var pref=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "pref" || return $?
  dt_debug ${fname} "pref=${pref}"
  env | awk -v pref="${pref}" -F'=' '{ if ($1 ~ pref) { printf "unset %s\n", $1; } }'
}

drop_all_ctxes() {
  local ctx var fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "*"
  for ctx in ${DT_CTXES[@]}; do
    unset "cache__${ctx}"
  done
  for var in ${DT_VARS[@]}; do
    unset ${var}
  done
  for var in ${DT_MREFS[@]}; do
    unset ${var}
  done
}

# sctx: source ctx
load_vars() {
  local var start_ctx sctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift
  if ! declare -f ${sctx} >/dev/null 2>&1; then
    dt_error ${fname} "Context ${BOLD}${sctx}${RESET} doesn't exist"
    return 99
  fi
  dt_debug ${fname} "Will init sctx=${BOLD}${sctx}${RESET}"
  start_ctx="${DT_START_CTX}"; DT_START_CTX=
  ${sctx}
  DT_START_CTX="${start_ctx}"
  dt_debug ${fname} "${BOLD}done${RESET}"
  for var in "$@"; do
    if ! declare -f ${var} >/dev/null 2>&1; then
      dt_error ${fname} "Variable ${BOLD}${var}${RESET} has not registered as function yet"
      return 99
    fi
    if ! declare -p $(var_pref ${sctx})${var} >/dev/null 2>&1; then
      dt_error ${fname} "Variable ${BOLD}${var}${RESET} doesn't exist in source ctx=${BOLD}${sctx}${RESET}, DT_CTX_STACK=${BOLD}${DT_CTX_STACK[@]}${RESET}"
      return 99
    fi
    var ${var} "$(${var} ${sctx})"
  done
}

## Consider function docker_build(), then the call "dt_register ctx_docker_pg_admin pg docker_methods"
## will generate function docker_build_pg() { dt_init_and_load_ctx && docker_build_pg }
dt_bind() {
  local ctx mref suffix methods method excluded fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx=$(echo "$1" | cut -d':' -f 1)
  suffix=$(echo "$1" | cut -d':' -f 2)
  methods=$(echo "$1" | cut -d':' -f 3)
  excluded=$(echo "$1" | cut -d':' -f 4)
  err_if_empty ${fname} "ctx suffix methods" || return $?
  if [ -n "${suffix}" ]; then suffix="_${suffix}"; fi
  methods=($(echo $(${methods})| sort))
  excluded=($(echo ${excluded}))
  if [ -n "${excluded}" ]; then dt_info ${fname} "${BOLD}excluded${RESET}=${excluded[@]}"; fi
  for method in ${methods[@]}; do
    mref=$(mref ${ctx} ${method})
    eval "${mref}=${method}${suffix}"
    if ! is_contained ${mref} DT_VARS; then DT_VARS+=(${mref}); fi
    if is_contained ${method}${suffix} excluded; then continue; fi
    if is_contained ${method}${suffix} DT_METHODS; then continue; else DT_METHODS+=(${method}${suffix}); fi
    dt_debug ${fname} "Register method: ${BOLD}${method}${suffix}${RESET}() { push_ctx ${ctx} && ${method} && pop_ctx; }"
    eval "function ${method}${suffix}() { push_ctx ${ctx} && ${method} && pop_ctx; }" || return $?
  done
}

mref() {
  local ctx=$1 method=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx method" || return $?
  echo "${ctx}__${method}"
}

get_method() {
  local mref ctx=$1 method=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx method" || return $?
  mref=${ctx}__${method}
  echo "$(eval echo "\$${mref}")"
}

dt_register() {
  local binding fname=$(fname "${FUNCNAME[0]}" "$0")
  DT_BINDINGS=($(for binding in ${DT_BINDINGS[@]}; do echo "${binding}"; done | sort))
  for binding in ${DT_BINDINGS[@]}; do dt_bind "${binding}"; done
}

dt_bindings() {
  local binding fname=$(fname "${FUNCNAME[0]}" "$0")
  for binding in ${DT_BINDINGS[@]}; do echo "${binding}"; done
}

dt_methods() {
  local method fname=$(fname "${FUNCNAME[0]}" "$0")
  DT_METHODS=($(for method in ${DT_METHODS[@]}; do echo "${method}"; done | sort))
  for method in ${DT_METHODS[@]}; do echo "${method}"; done
}

dt_vars() {
  local var fname=$(fname "${FUNCNAME[0]}" "$0")
  DT_VARS=($(for var in ${DT_VARS[@]}; do echo "${var}"; done | sort))
  for var in ${DT_VARS[@]}; do val="$(eval echo "\$${var}")"; echo "${var}=${val}"; done
}

dt_paths() {
  export DTOOLS=$(realpath $(dirname "$(realpath $self)")/..)
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
dt_defaults() {
  export DT_DRYRUN="n"
  export DT_ECHO="y"
  export DT_ECHO_COLOR="${YELLOW}"
  export DT_ECHO_STDOUT="n"
  export PROFILE_CI=
  export DT_SEVERITY
  if [ -z "${DT_SEVERITY}" ]; then DT_SEVERITY=4; fi
  DT_START_CTX=
  DT_BINDINGS=()
  DT_CTXES=()
  DT_CTX_STACK=()
  DT_METHODS=()
  DT_VARS=()
}
