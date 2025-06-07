function _check_optarg() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "${OPTARG:0:1}" = "-" ]; then
    dt_error ${fname} "Option ${opt} requires an argument, but got another option '-${OPTARG}' instead value."
    return 99
  fi
}

# Usage: dt_set_ctx -c ${ctx}
function dt_set_ctx() {
  local vars val var ctx ctx_file fname dump
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ -z "${id}" ]; then; ID=$((${ID}+1)); id=${ID}; fi
  ctx=
  ctx_file=
  OPTSTRING=":c:"
  dt_debug ${fname} "${BOLD}ID=${id}${RESET}: BEGIN"
  while getopts ${OPTSTRING} opt; do
    dt_debug ${fname} "${BOLD}ID=${id}${RESET}: opt=${opt}, OPTARG=${OPTARG}, OPTIND=${OPTIND}"
    case ${opt} in
      c) _check_optarg || return $?
        if [ -n "${ctx}" ]; then dt_error ${fname} "Option '-c' cannot be used multiple times"; return 99; fi
        ctx=${OPTARG}
        ctx_file="${DT_CTXES}/${ctx}.txt"
        ;;
      :) echo "Option -${OPTARG} requires an argument."; return 88;;
      ?) echo "Invalid option: '-${OPTARG}'."; return 99;;
    esac
  done
  shift $((OPTIND - 1))
  if [ -n "$1" ]; then dt_error ${fname} "Positional parameters are not supported: \$@='$@'"; return 99; fi
  rm -f '${ctx_file}'
  vars=($(eval echo "\${__vars}"))
  dt_debug ${fname} "${BOLD}ID=${id}${RESET}: ctx=${BOLD}${ctx}${RESET}, vars=${vars}"
  for var in ${vars[@]}; do
    val=$(eval echo "\$${var}")
    dt_debug ${fname} "${BOLD}ID=${id}${RESET}: ${BOLD}setting${RESET} var ${BOLD}${var}${RESET}=${val}"
    eval "${var}=\$'$(dt_escape_quote ${val})'"
    if [ -n "${ctx_file}" ]; then
      echo -e "${var}=\$'$(dt_escape_quote ${val})'" >> "${ctx_file}"
    fi
  done
  dt_debug ${fname} "${BOLD}ID=${id}${RESET}: END"
}

function dt_skip_if_initialized() {
  local ctx_file fname
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx_file="${DT_CTXES}/${ctx}.txt"
  if [ -f "${ctx_file}" ]; then
    dt_info ${fname} "${BOLD}ID=${id}${RESET}: ${BOLD}${ctx}${RESET} has already been initialized, ${BOLD}ctx cache${RESET} is in file ${BOLD}${ctx_file}${RESET}, ${BOLD}skip${RESET}"
  else
    return 101
  fi
}

# Consider function docker_build(), then the call "dt_register ctx_docker_pg_admin pg docker_methods"
# will generate function docker_build_pg() { dt_init_and_load_ctx && docker_build_pg }
function dt_register() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local ctx=$1
  dt_err_if_empty ${fname} "ctx" || return $?
  local suffix=$2
  shift 2
  local methods=("$@")
  if [ -n "${methods}" ] && [ -z "${suffix}" ]; then dt_error ${fname} "err=${err}"; return ${err}; fi
  for method in ${methods[@]}; do
    eval "function ${method}_${suffix}() { dt_load_vars -c ${ctx} && ${method} }"
  done
}

function _dt_parse_ctxes() {
  local fname opt OPTSTRING OPTIND OPTARG
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  OPTSTRING=":c:v:m:eu"
  while getopts ${OPTSTRING} opt; do
    dt_debug ${fname} "${BOLD}ID=${id}${RESET}: opt=${opt}, OPTARG=${OPTARG}"
    case ${opt} in
      c) _check_optarg || return $?; ctxes+=(${OPTARG});;
      v) _check_optarg || return $?; filter+=(${OPTARG});;
      m) _check_optarg || return $?; map+=(${OPTARG});;
      e) _check_optarg || return $?; export="y";;
      u) _check_optarg || return $?; unexport="y";;
      :) echo "Option -${OPTARG} requires an argument."; return 88;;
      ?) echo "Invalid option: '-${OPTARG}'."; return 99;;
    esac
  done
}

function _remap() {
  local fname pair old new
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  for pair in ${map[@]};  do
    old=$(echo ${pair} | sed -E -e "s/^(.+)=>.+$/\1/") || return $?
    new=$(echo ${pair} | sed -E -e "s/^.+=>(.+)$/\1/") || return $?
    if [ "${old}" = "${var}" ]; then
      dt_debug ${fname} "${BOLD}ID=${id}${RESET}: ctx=${ctx}: var ${BOLD}${old}${RESET} will be remapped to ${BOLD}${new}${RESET}"
      var=${new}
      break
    fi
  done
}

# -m 'FOO=>B' -m 'BAR=>X': rename vars during loading; this option can be used multiple times, NOTE: mapping must be passed inside single quotes
# -v FOO -v BAR: list of vars to be loaded, if empty - all vars of all ctxes will be loaded; this option can be used multiple times
# -c %ctx_name%: contains name of ctx; this option can be used multiple times; every ctx is callable, so ecah %ctx_name% in the array "ctxes" will be called to init appropriate ctx
# -e: export varibale
# -u: UNexport varibale
function dt_load_vars() {
  local fname id ctxes filter map export unexport ctx ctx_file vars var val
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ID=$((${ID}+1)); id=${ID}
  ctxes=()
  filter=()
  map=()
  export=
  unexport=
  dt_debug ${fname} "${BOLD}ID=${id}${RESET}: BEGIN"
  _dt_parse_ctxes $@ || return $?
  dt_debug ${fname} "${BOLD}ID=${id}${RESET}: ctxes='${ctxes}', filter='${filter}', map='${map}'"
  for ctx in ${ctxes[@]}; do
    ctx_file="${DT_CTXES}/${ctx}.txt"
    dt_skip_if_initialized; if [ "$?" != 0 ]; then
      dt_info ${fname} "${BOLD}ID=${id}${RESET}: Lazy initialization of ctx ${BOLD}${ctx}${RESET}"
      ${ctx} || return $?
      dt_info ${fname} "${BOLD}ID=${id}${RESET}: ctx ${BOLD}${ctx}${RESET} is initialized"
    fi
    dt_info ${fname} "${BOLD}ID=${id}${RESET}: sourcing file ${ctx_file}"
    . "${ctx_file}" || return $?
    if [ -n "${filter}" ]; then
      vars=("${filter[@]}")
    else
      vars=($(eval echo "\${__vars}"))
    fi
    dt_debug ${fname} "vars=${vars}"
    for var in ${vars[@]}; do
      val=$(eval echo "\$${var}")
      _remap || $?
      dt_debug ${fname} "${BOLD}ID=${id}${RESET}: ctx=${ctx}: ${BOLD}loading${RESET} var ${BOLD}${var}${RESET}=${val}"
      eval $(echo "${var}=\"${val}\"")
      if [ "${export}" = "y" ]; then dt_exec "export ${var}" || return $?; fi
      if [ "${unexport}" = "y" ]; then dt_exec "typeset +x ${var}" || return $?; fi
    done
  done
  dt_debug ${fname} "${BOLD}ID=${id}${RESET}: END"
}
