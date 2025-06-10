# Usage: dt_export ctx_service_pg_tetrix
function load_vars() {
  local fname ctx ctxes vars dctx prf dprf export mode; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  mode=$1;
  if [ "${mode}" = "-e" ]; then mode="export"; shift
  elif [ "${mode}" = "-u" ]; then mode="unset"; shift
  else mode=; fi
  ctxes=($(echo $1)); dt_err_if_empty ${fname} "ctxes" || return $?
  vars=($(echo $2)); dt_err_if_empty ${fname} "vars" || return $?
  dctx=$3
  for ctx in ${ctxes[@]}; do
    ${ctx}
    prf=$(var_prf ${ctx})
    dprf=$(var_prf ${dctx})
    if [ "${vars}" = "*" ]; then
      . <(env | while read var; do
        awk -v prf="${prf}" -v mode="${mode}" -v dprf="${dprf}" -F'=' '{
          if ($1 ~ prf) { sub(prf, "", $1);
            if ( mode == "unset" ) { printf "%s %s%s\n", mode, dprf, $1 }
            else { printf "%s %s%s=\"%s\"\n", mode, dprf, $1, $2  } }
        }'
      done)
    else
      for var in ${vars[@]}; do
        # skip var if it doesn't exist in ctx=${ctx}
        if ! declare -p ${prf}${var} >/dev/null 2>&1; then continue; fi
        if [ "${mode}" = "unset" ]; then
          dt_debug ${fname} "${mode} ${dprf}${var}"
          ${mode} ${dprf}${var}
        else
          val=$(eval echo "\${${prf}${var}}")
          dt_debug ${fname} "${mode} ${dprf}${var}=\"${val}\""
          eval "${mode} ${dprf}${var}=\"${val}\""
        fi
      done
    fi
  done
}

function drop_ctx() {
  local fname ctx prf
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  dt_debug ${fname} "${ctx}"
  prf=$(var_prf ${ctx})
  . <(env | while read var; do
    awk -v prf="${prf}" -F'=' '{ if ($1 ~ prf) { printf "unset %s\n", $1; } }'
  done)
  unset "cache__${ctx}"
}

function drop_all_ctxes() {
  local fname
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "*"
  . <(export | while read var; do
    awk -F'=' '{if ($1 ~ "ctx_") { printf "unset %s\n", $1 }}';
    awk -F'=' '{if ($1 ~ "cache__") { printf "unset %s\n", $1 }}'
  done)
}

function var_prf() {
  local prf
  if [ -n "$1" ]; then prf="$1__"; fi
  echo "${prf}"
}

# get var
function gvar() {
  local fname var val; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "var" || return $?
  var=$2
  var=$(var_prf $1)$2
  val=$(eval echo "\${${var}}")
  echo "${val}"
}

# set var ${var} in ctx ${ctx} if it doesn't exist in this ctx
function var() {
  local fname ctx var val prf pvar; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "var" || return $?
  var=$2; dt_err_if_empty ${fname} "var" || return $?
  val=$3
  prf=$(var_prf ${ctx})
  pvar=${prf}${var}
  # if var exist - skip
  if declare -p ${pvar} >/dev/null 2>&1; then return 0; fi
  dt_debug ${fname} "setting var=${prf}${BOLD}${var}${RESET}; val=${BOLD}${val}${RESET}"
  eval "export ${pvar}=\"${val}\""
}

# Consider function docker_build(), then the call "dt_register ctx_docker_pg_admin pg docker_methods"
# will generate function docker_build_pg() { dt_init_and_load_ctx && docker_build_pg }
function dt_register() {
  local fname ctx suffix methods method
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  suffix=$2; dt_err_if_empty ${fname} "suffix" || return $?
  methods=($(echo "$3"))
  for method in ${methods[@]}; do
    bound_method=$(echo ${method} | sed -E -e 's/^_(.+)$/\1/')
#    dt_debug ${fname} "function ${method}_${suffix}() { load_vars ${ctx} '*' && ${method}; }"
    eval "function ${bound_method}_${suffix}() { ${method} ${ctx}; }" || return $?
  done
}

function dt_cache() {
  local fname ctx; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  dt_err_if_empty ${fname} "ctx" || return $?
  export cache__${ctx}
}

function dt_cached() {
  local fname ctx; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  dt_err_if_empty ${fname} "ctx" || return $?
  declare -p "cache__${ctx}" >/dev/null 2>&1; err=$?
  if [ "${err}" = 0 ]; then dt_debug ${fname} "Context ${BOLD}${ctx}${RESET} has already initialized."; fi
  return ${err}
}

# shortcut
function dt_export() {
  export | grep -v __
}