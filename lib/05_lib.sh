sleep_1() { exec_cmd "sleep 1"; }
sleep_5() { exec_cmd "sleep 5"; }

ser_val() {
  local val=$1
  if echo "${val}" | grep "'" >/dev/null 2>&1; then
    val="$(escape_quote "${val}")"
    val="$'${val}'"
  elif echo "${val}" | grep ' ' >/dev/null 2>&1; then
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

drop_vars_by_pref() {
  local var pref=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "pref" || return $?
  dt_debug ${fname} "pref=${pref}"
  env | awk -v pref="${pref}" -F'=' '{ if ($1 ~ pref) { printf "unset %s\n", $1; } }'
}

#dt_vars() {
#  local var fname=$(fname "${FUNCNAME[0]}" "$0")
#  DT_VARS=($(for var in ${DT_VARS[@]}; do echo "${var}"; done | sort))
#  for var in ${DT_VARS[@]}; do val=$(escape_quote "$(eval echo "\$${var}")"); echo "${var}=$'${val}'"; done
#}

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

get_func() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if ! declare -f "$1" >/dev/null 2>&1; then
    dt_error "${fname}" "Function $1 doesn't exist"
    return 99
  else
    echo "$1"
  fi
}

function os_arch() {
  echo $(uname -m)
}

function os_kernel() {
  echo "$(uname -s)"
}

function os_name() {
  if [ "$(os_kernel)" = "Linux" ] && [ -f "/etc/os-release" ]; then
    echo $(. /etc/os-release && echo "${ID}")
  elif [ "$(os_kernel)" = "Darwin" ]; then
    echo "macos"
  else
    "$(os_kernel)"
  fi
}

function os_codename() {
  if [ "$(os_kernel)" = "Linux" ] && [ -f "/etc/os-release" ]; then
    echo $(. /etc/os-release && echo "${VERSION_CODENAME}")
  fi
}

function brew_prefix() {
  echo $(brew --prefix)
}

add_env() {
  envs["$1"]="$2"
  ENVS+=("$1")
}

inline_envs() {
  local result var val fname=inline_envs
  result=()
  for var in ${ENVS[@]}; do
    val=${envs["${var}"]}
    dt_debug ${fname} "var=${var}; val=${val}"
    val=$(ser_val "${val}")
    result+=("${var}=${val}")
  done
  echo "${result[@]}"
}

service_mode() {
  local fname=mode
  if [ "${MODE}" = "docker" ]; then
    echo "docker"
  elif [ "${MODE}" = "host" ]; then
    echo "host"
  else
    dt_error ${fname} "Unknown mode: MODE=${MODE}"
    return 99
  fi
}

function dt_sudo() {
  if [ "$(os_kernel)" = "Linux" ]; then
    echo "sudo"
  fi
}

SUDO=$(dt_sudo)