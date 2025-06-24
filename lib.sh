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

# Usage: set_caller $1
# $1: is an arg $1 of calling function
# Vars "ctx" and "caller" are NOT local, they must be defined in caller
set_caller() {
  if [ -n "$1" ]; then caller=$1; else caller=${ctx}; fi
  dt_debug set_caller "caller=${BOLD}${caller}${RESET}, ctx=${BOLD}${ctx}${RESET}"
  if [ -n "${DT_CTX}" ]; then return 0; fi
  DT_CTX=${caller}
}

# Vars ctx and caller are not local, they must be defined in caller
is_cached() {
  local ctx_pair fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx caller" || return $?
  if [ "${ctx}" != "${caller}" ]; then return 99; fi
  ctx_pair="${caller}__${ctx}"
  dt_debug ${fname} "ctx_pair=${BOLD}${ctx_pair}${RESET}"
  if ! declare -p ${ctx_pair} >/dev/null 2>&1; then return 99; fi
  dt_debug ${fname} "Ctx pair ${BOLD}${ctx_pair}${RESET} is cached"
  DT_CTX=
}

# Vars ctx and caller are not local, they must be defined in caller
cache_ctx() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "ctx caller" || return $?
  dt_debug ${fname} "ctx=${ctx}, caller=${caller}"
  if [ "${ctx}" != "${caller}" ]; then return 0; fi
  local ctx_pair="${caller}__${ctx}"
  if declare -p ${ctx_pair} >/dev/null 2>&1; then dt_error ${fname} "ctx_pair=${BOLD}${ctx_pair}${RESET} exists"; return 99; fi
  dt_debug ${fname} "Caching ctx pair ${BOLD}${ctx_pair}${RESET}"
  DT_CTX=
  dt_debug ${fname} "DT_CTX=${DT_CTX}"
  eval "${ctx_pair}=1"
  DT_VARS+=(${ctx_pair})
}

switch_ctx() {
  local dt_ctx ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "Switching to ctx ${BOLD}${ctx}${RESET}" && \
  err_if_empty ${fname} "ctx" && \
  DT_CTX= && \
  ${ctx} && \
  DT_CTX=${ctx}
}

# get value of var in some ctx
# ovar: original var
# octx: original ctx
get_var() {
  local val octx ctx var ovar=$1 octx=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${octx}" ]; then ctx="${octx}"; else ctx="${DT_CTX}"; fi
  if [ -z "${ctx}" ]; then
    dt_error ${fname} "Context for variable ${BOLD}${var}${RESET} was not provided: ${BOLD}DT_CTX${RESET} is empty and ${BOLD}octx${RESET} is empty"
    return 99
  fi
  var=$(var_pref ${ctx})${ovar} || return $?
  if declare -p ${var} >/dev/null 2>&1; then
    val=$(eval echo \$${var})
    echo "${val}"
  else
    dt_error ${fname} "Variable ${BOLD}${var}${RESET} doesn't exist"
    return 99
  fi
}

# sets or resets var in some ctx
# ovar: original var
# octx: original ctx
var() {
  local mode val ovar ctx octx fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "$1" = "-r" ]; then mode="reset"; shift; else mode="set"; fi
  ovar=$1; val=$2 octx=$3
  err_if_empty ${fname} "ovar" || return $?
  if [ -n "${octx}" ]; then ctx="${octx}"; else ctx="${DT_CTX}"; fi
  if [ -z "${ctx}" ]; then
    dt_error ${fname} "Context for variable ${BOLD}${var}${RESET} was not provided: ${BOLD}DT_CTX${RESET} is empty and ${BOLD}octx${RESET} is empty"
    return 99
  fi
  var=$(var_pref ${ctx})${ovar} || return $?
  if declare -p ${var} >/dev/null 2>&1; then
    if [ "${mode}" != "reset" ]; then return 0; fi
  fi
  val=$(ser_val "${val}")
  dt_debug ${fname} "Setting var ${BOLD}${var}${RESET} to val ${BOLD}${val}${RESET}, mode=${mode}"
  eval "${var}=${val}"
  if ! is_contained ${var} DT_VARS; then DT_VARS+=(${var}); fi
#  dt_debug ${fname} "Register function: ${ovar}() { get_var ${ovar} \$1; }"
  eval "${ovar}() { get_var ${ovar} \$1; }"
#  dt_debug ${fname} "val=$(${ovar})"
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
  for var in ${DT_VARS[@]}; do
    unset ${var}
  done
  for var in ${DT_METHODS[@]}; do
    unset -f ${var}
  done
}

# sctx: source ctx
load_vars() {
  local var dt_ctx sctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift
  if ! declare -f ${sctx} >/dev/null 2>&1; then
    dt_error ${fname} "Context ${BOLD}${sctx}${RESET} doesn't exist"
    return 99
  fi
  dt_ctx=${DT_CTX}; DT_CTX=
  dt_debug ${fname} "Will init ctx ${BOLD}${sctx}${RESET}, DT_CTX=${DT_CTX}, previous DT_CTX=${dt_ctx}"
  ${sctx} || return $?
  DT_CTX=${dt_ctx}
  dt_debug ${fname} "Begining load vars from ${BOLD}${sctx}${RESET} to ${BOLD}${DT_CTX}${RESET}"
  for var in "$@"; do
    if ! declare -f ${var} >/dev/null 2>&1; then
      dt_error ${fname} "Variable ${BOLD}${var}${RESET} has not registered as function yet"
      return 99
    fi
    if ! declare -p $(var_pref ${sctx})${var} >/dev/null 2>&1; then
      dt_error ${fname} "Variable ${BOLD}${var}${RESET} doesn't exist in source ctx=${BOLD}${sctx}${RESET}, DT_CTX=${BOLD}${DT_CTX}${RESET}"
      return 99
    fi
    var ${var} "$(${var} ${sctx})" || return $?
  done
  dt_debug ${fname} "${BOLD}Done${RESET}"
}

## Consider function docker_build(), then the call "dt_register ctx_docker_pg_admin pg docker_methods"
## will generate function docker_build_pg() { dt_init_and_load_ctx && docker_build_pg }
dt_bind() {
  local body ctx suffix methods method excluded fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx=$(echo "$1" | cut -d':' -f 1)
  suffix=$(echo "$1" | cut -d':' -f 2)
  methods=$(echo "$1" | cut -d':' -f 3)
  excluded=$(echo "$1" | cut -d':' -f 4)
  err_if_empty ${fname} "ctx suffix methods" || return $?
  dt_debug ${fname} "ctx=${BOLD}${ctx}${RESET}, suffix=${suffix}, methods=${methods}"
  if [ -n "${suffix}" ]; then suffix="_${suffix}"; fi
  methods=($(echo $(${methods})| sort))
  excluded=($(echo ${excluded}))
  if [ -n "${excluded}" ]; then dt_info ${fname} "${BOLD}excluded${RESET}=${excluded[@]}"; fi
  for method in ${methods[@]}; do
    if is_contained ${method}${suffix} excluded; then continue; fi && \
    if [ declare -p ${method}${suffix} >/dev/null 2>&1 ] || [ declare -p ${ctx}__${method} >/dev/null 2>&1 ]; then
      dt_error ${fname} "Duplicated method=${BOLD}${method}${suffix}${RESET}"
      return 99
    fi
    dt_debug ${fname} "Registering methods: ${BOLD}${method}${suffix}${RESET} and ${BOLD}${ctx}__${method}${RESET}"
    DT_METHODS+=(${method}${suffix})
    DT_METHODS+=(${ctx}__${method})
    body="{ local dtc_ctx=\${DT_CTX}; DT_CTX=\${DT_CTX}; switch_ctx ${ctx} && ${method} \$@; local err=\$?; DTC_CTX=\${dt_ctx}; return \${err}; }" && \
    eval "function ${method}${suffix}() ${body}" && \
    eval "function ${ctx}__${method}() ${body}" || return $?
  done
}

dt_register() {
  local binding fname=$(fname "${FUNCNAME[0]}" "$0")
  DT_BINDINGS=($(for binding in ${DT_BINDINGS[@]}; do echo "${binding}"; done | sort))
  for binding in ${DT_BINDINGS[@]}; do dt_bind "${binding}" || return $?; done
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

function reinit_dtools() {
  . ${DTOOLS}/core/rc.sh
}

add_deps() {
  local ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0"); shift
  local deps=($(echo "$@"))
  err_if_empty ${fname} "ctx deps" && \
  for dep in ${deps[@]}; do
    dt_debug ${fname} "ctx=${ctx} dep=${dep}"
    DT_DEPS+=("${ctx} ${dep}")
  done
}

init_deps() {
  tsort_deps | while read dep; do ${dep} || return $?;
#    if [ "ctx_conn_app_pg_tetrix" = "${dep}" ] || [ "${A}" = 1 ]; then
#      A=1; dt_warning ">>>>>>>>>>>>>" $(MINOR)
#    fi
  done
}

tsort_deps() {
  printf "%s\n" "${DT_DEPS[@]}" > "${DT_CTXES_DEPS}"
  tsort "${DT_CTXES_DEPS}" | tac
}

list_deps(){
  cat ${DT_CTXES_DEPS}
}

dryrun_off() { DT_DRYRUN="n"; }
dryrun_on() { DT_DRYRUN="y"; }

exec_cmd () {
  local cmd="$@" fname=$(fname "${FUNCNAME[0]}" "$0")
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
      >&2 echo -e "${BOLD}${DT_ECHO_COLOR}[dtools][DT_ECHO][exec_cmd]${RESET}"
      >&2 echo -e "${DT_ECHO_COLOR}${cmd}${RESET}"
    fi
    eval "$(echo -e "${cmd}")" || return $?
  fi
}

#cmd_echo() {
#  local fname=$(fname "${FUNCNAME[0]}" "$0")
#  local saved_DRYRUN saved_ECHO
#  saved_DRYRUN=${DT_DRYRUN}
#  saved_ECHO=${DT_DRYRUN}
#  dryrun_on
#  DT_ECHO_STDOUT="y"
#  DT_ECHO="n"
#  $@ || return $?
#  DT_ECHO_STDOUT="n"
#  DT_DRYRUN=${saved_DRYRUN}
#  DT_ECHO=${saved_ECHO}
#}

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
  export DT_CTXES_DEPS="${DT_LOGS}/ctxes_deps.txt"
  export DT_REPORTS="${DT_ARTEFACTS}/reports"
  export DT_TOOLCHAIN=${DT_ARTEFACTS}/toolchain
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  if [ ! -d "${DT_REPORTS}" ]; then mkdir -p ${DT_REPORTS}; fi
  if [ ! -d "${DT_TOOLCHAIN}" ]; then mkdir -p ${DT_TOOLCHAIN}; fi
  if [ -f "${DT_CTXES_DEPS}" ]; then rm "${DT_CTXES_DEPS}"; fi
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
  DT_BINDINGS=()
  DT_METHODS=()
  DT_VARS=()
  DT_DEPS=()
  DT_CTX=
  DT_STAND='n'
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

function dt_init() {
  if [ -n "${BASH_SOURCE}" ]; then local self="${BASH_SOURCE[0]}"; else local self="$1"; fi
  local self_dir="$(dirname $(realpath "${self}"))"
  . "${self_dir}/colors.sh" && \
  . "${self_dir}/lib.sh" && \
  drop_all_ctxes && \
  dt_paths && \
  dt_defaults && \
  dt_rc_load $(basename "${self_dir}") "${self_dir}" && \
  . "${self_dir}/clickhouse/rc.sh" && \
  . "${self_dir}/pg/rc.sh" && \
  . "${self_dir}/redis/rc.sh" && \
  . "${self_dir}/rabbitmq/rc.sh" && \
  . "${self_dir}/cargo/rc.sh" && \
  . "${self_dir}/python/rc.sh" && \
  . "${DT_TOOLS}/rc.sh" && \
  . "${DT_STANDS}/rc.sh" && \
  if [ -f "${DT_LOCALS}/rc.sh" ]; then . "${DT_LOCALS}/rc.sh" || return $?; fi
  dt_register
}