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

escape_quote() { echo "$@" | sed -e "s/'/\\\\'/g"; }
escape_dollar() { echo "$@" | sed -e "s/\\$/\\\\$/g" | sed -e "s/'/\\\\'/g"; }

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



drop_vars_by_pref() {
  local var pref=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "pref" || return $?
  dt_debug ${fname} "pref=${pref}"
  env | awk -v pref="${pref}" -F'=' '{ if ($1 ~ pref) { printf "unset %s\n", $1; } }'
}

drop_vars() {
  local var fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "*"
  for var in ${DT_VARS[@]}; do
    unset ${var}
  done
  DT_VARS=()
}

drop_all() {
  local ctx var fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "*"
  for var in ${DT_VARS[@]}; do
    unset ${var}
  done
  for var in ${DT_METHODS[@]}; do
    unset -f ${var}
  done
  for var in ${DT_CTXES[@]}; do
    unset -f ${var}
  done
  DT_VARS=()
  DT_METHODS=()
  DT_CTXES=()
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



dt_ctxes() {
  local var fname=$(fname "${FUNCNAME[0]}" "$0")
  DT_CTXES=($(for var in ${DT_CTXES[@]}; do echo "${var}"; done | sort))
  for var in ${DT_CTXES[@]}; do echo "${var}"; done
}

dt_vars() {
  local var fname=$(fname "${FUNCNAME[0]}" "$0")
  DT_VARS=($(for var in ${DT_VARS[@]}; do echo "${var}"; done | sort))
  for var in ${DT_VARS[@]}; do val="$(eval echo "\$${var}")"; echo "${var}=${val}"; done
}

set_dryrun_off() { DT_DRYRUN="n"; }
set_dryrun_on() { DT_DRYRUN="y"; }

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
  else
    if [ "${DT_ECHO}" = "y" ]; then
      >&2 echo -e "${BOLD}${DT_ECHO_COLOR}[dtools][DT_ECHO][exec_cmd]${RESET}"
      >&2 echo -e "${DT_ECHO_COLOR}${cmd}${RESET}"
    fi
    eval "$(echo -e "${cmd}")" || return $?
  fi
}

is_var_changed(){
  local ecode var=$1 pvar new_val prev_val fname=$(fname "${FUNCNAME[0]}" "$0")
  pvar="PREV_${var}"
  err_if_empty ${fname} "var" && \
  new_val="$(eval echo "\$${var}")" && \
  prev_val="$(eval echo "\$${pvar}")" && \
  err_if_empty ${fname} "new_val" && \
  if ! declare -p ${pvar} >/dev/null 2>&1; then
    ecode=0
  elif [ "${prev_val}" != "${new_val}" ]; then
    ecode=0
  else
    ecode=99
  fi && \
  eval "${pvar}=${new_val}" && \
  return ${ecode}
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
  export DT_CTXES_DEPS="${DT_LOGS}/ctxes_deps.txt"
  export DT_REPORTS="${DT_ARTEFACTS}/reports"
  export DT_TOOLCHAIN=${DT_ARTEFACTS}/toolchain
  export DL="${DT_TOOLCHAIN}/dl"
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
  export PROFILE_CI=
  export DT_SEVERITY=4
  DT_BINDINGS=()
  DT_METHODS=()
  DT_VARS=(DT_RECORD DT_TABLE)
  DT_DEPS=()
  DT_CTX=
  DT_CTXES=()
  DT_STAND='n'
}

function dt_init() {
  if [ -n "${BASH_SOURCE}" ]; then local self="${BASH_SOURCE[0]}"; else local self="$1"; fi
  local self_dir="$(dirname $(realpath "${self}"))"
  drop_all && \
  dt_paths && \
  dt_defaults && \
  dt_rc_load $(basename "${self_dir}") "${self_dir}" && \
#  . "${self_dir}/clickhouse/rc.sh" && \
#  . "${self_dir}/pg/rc.sh" && \
#  . "${self_dir}/redis/rc.sh" && \
#  . "${self_dir}/rabbitmq/rc.sh" && \
#  . "${self_dir}/cargo/rc.sh" && \
#  . "${self_dir}/python/rc.sh" && \
#  . "${DT_TOOLS}/rc.sh" && \
#  . "${DT_STANDS}/rc.sh" && \
  if [ -f "${DT_LOCALS}/rc.sh" ]; then . "${DT_LOCALS}/rc.sh" || return $?; fi
#  dt_register
}