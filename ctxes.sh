# "initialized_ctxes" is a cache for ctx that have already been initialized.
# NOTE: "initialized_ctxes" is reset every time the command ". ./dtools/rs.sh" is run.
initialized_ctxes=()

function _check_optarg() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "${OPTARG:0:1}" = "-" ]; then
    dt_error ${fname} "Option ${opt} requires an argument, but got another option '-${OPTARG}' instead value."
    return 99
  fi
}

# Example: . <(dt_set_ctx ${ctx})
function dt_set_ctx() {
  local vars val var ctx fctx prefix fname dump
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=
  fctx=
  prefix=
  OPTSTRING=":c:d"
  while getopts ${OPTSTRING} opt; do
    dt_debug ${fname} "opt=${opt}, OPTARG=${OPTARG}, OPTIND=${OPTIND}"
    case ${opt} in
      c) _check_optarg || return $?
        if [ -n "${ctx}" ]; then dt_error ${fname} "Option '-c' cannot be used multiple times"; return 99; fi
        ctx=${OPTARG}
        prefix=_${ctx}__
        ;;
      d) fctx="${DT_LOGS}/ctxes/${ctx}"
         if [ ! -d "$(dirname ${fctx})" ]; then mkdir -p "$(dirname ${fctx})"; fi
         :> "${fctx}"
        ;;
      :) echo "Option -${OPTARG} requires an argument."; return 88;;
      ?) echo "Invalid option: '-${OPTARG}'."; return 99;;
    esac
  done
  shift $((OPTIND - 1))
  if [ -n "$1" ]; then dt_error ${fname} "Positional parameters are not supported: \$@='$@'"; return 99; fi
  vars=$(eval echo "\${vars_${ctx}}")
  for var in $(eval echo "\${${vars}[@]}"); do
    val=$(eval echo "\$${var}")
    dt_debug ${fname} "ctx=${ctx}: ${BOLD}setting${RESET} var ${BOLD}${var}${RESET}=${val}"
    if [ -z "${val}" ]; then
      dt_warning ${fname} "Var ${BOLD}${var}${RESET} is ${BOLD}empty${RESET}"
    fi
    eval "${prefix}${var}=\$'$(dt_escape_quote ${val})'"
    if [ -n "${fctx}" ]; then
      echo "${prefix}${var}=\$'$(dt_escape_quote ${val})'" >> "${fctx}"
    fi
  done
  initialized_ctxes+=(${ctx})
  dt_debug ${fname} "${BOLD}EXIT${RESET}"
}

function dt_ctx_is_initialized() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  for c in ${initialized_ctxes[@]};  do
    dt_debug ${fname} "c=${c}, ctx=${ctx}"
    if [ "${c}" = "${ctx}" ]; then
      dt_debug ${fname} "${BOLD}hit${RESET}"
      return 10
    fi
  done
}

function dt_skip_if_initialized() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "initialized_ctxes=${BOLD}${initialized_ctxes}${RESET}"
  dt_ctx_is_initialized; err=$?
  if [ "${err}" = 10 ]; then
    dt_debug ${fname} "${BOLD}${ctx}${RESET} has already been initialized, ${BOLD}skip${RESET}"
  fi

  if [ "${err}" != 0 ]; then
    return ${err}
  fi
}

# Consider function docker_build()
# dt_register ctx_docker_pg_admin pg docker_methods
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

function _dt_init_ctx() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_ctx_is_initialized "${ctx}"; err=$?
  if [ "${err}" = 99 ]; then
   return $?
  elif [ "${err}" = 10 ]; then
   dt_debug ${fname} "ctx '${BOLD}${ctx}${RESET}' has already been initialized, ${BOLD}skip${RESET}"
   return 0
  fi
  dt_info ${fname} "initializing ctx '${ctx}' ..."
  ${ctx}
}

function _dt_parse_ctxes() {
  local fname opt OPTSTRING OPTIND OPTARG
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  OPTSTRING=":c:v:m:e:u:"
  while getopts ${OPTSTRING} opt; do
    dt_debug ${fname} "opt=${opt}, OPTARG=${OPTARG}"
    case ${opt} in
      c) _check_optarg || return $?; ctxes+=(${OPTARG});;
      v) _check_optarg || return $?; filter+=(${OPTARG});;
      m) _check_optarg || return $?; map+=(${OPTARG});;
      e) _check_optarg || return $?; export="${OPTARG}";;
      u) _check_optarg || return $?; unexport="${OPTARG}";;
      :) echo "Option -${OPTARG} requires an argument."; return 88;;
      ?) echo "Invalid option: '-${OPTARG}'."; return 99;;
    esac
  done
}

function _remap() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  for pair in ${map[@]};  do
    old=$(echo ${pair} | sed -E -e "s/^(.+)=>.+$/\1/") || return $?
    new=$(echo ${pair} | sed -E -e "s/^.+=>(.+)$/\1/") || return $?
    if [ "${old}" = "${var}" ]; then
      dt_debug ${fname} "${BOLD}match${RESET} var=${BOLD}${var}${RESET}, old=${BOLD}${old}${RESET}, new=${new}"
      dt_debug ${fname} "ctx=${ctx}: ${BOLD}loading remapped${RESET} var ${BOLD}${new}${RESET}=${val}"
      eval "${new}=\$${prefix}${var}" || return $?
      vname=${new}
      remapped="y"
      break
    fi
  done
}

function _export() {
  if [ "${export}" = "both" ]; then
    dt_exec "export ${prefix}${vname}" || return $?
    dt_exec "export ${vname}" || return $?
  elif [ "${export}" = "pref" ]; then
    dt_exec "export ${prefix}${vname}" || return $?
  elif [ "${export}" = "nopref" ]; then
    dt_exec "export ${vname}" || return $?
  fi
}

function _unexport() {
  if [ "${unexport}" = "both" ]; then
    dt_exec "typeset +x ${prefix}${vname}" || return $?
    dt_exec "typeset +x ${vname}" || return $?
  elif [ "${unexport}" = "pref" ]; then
    dt_exec "typeset +x ${prefix}${vname}" || return $?
  elif [ "${unexport}" = "nopref" ]; then
    dt_exec "typeset +x ${vname}" || return $?
  fi
}

# -m FOO=>B -m BAR=>X: rename vars during loading; can be used multiple times
# -v FOO -v BAR: list of vars to be loaded, if empty - all vars of all ctxes will be loaded; can be used multiple times
# -c %ctx_name%: contains name of ctx; can be used multiple times; every ctx is callable, so ecah %ctx_name% in the array "ctxes" will be called to init appropriate ctx
# -e pref|nopref|both: export varibale, 3 modes: "pref" adds ctx prefix when export var, "nopref" exports var without any prefix, "both" - nopref + pref
# -u pref|nopref|both: UNexport varibale, 3 modes: "pref" adds ctx prefix when unexport var, "nopref" unsets var without any prefix, "both" - nopref + pref
function dt_load_vars() {
  local fname ctxes filter map ctx vars var val new old pair vname export unexport remapped prefix
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctxes=()
  filter=()
  map=()
  export=
  unexport=
  _dt_parse_ctxes $@; err=$?
  if [ "${err}" != 0 ]; then dt_error ${fname} "Error while parsing args: err=${err}"; return ${err}; fi
  dt_debug ${fname} "ctxes='${ctxes}', filter='${filter}', map='${map}'"
  for ctx in ${ctxes[@]}; do
    prefix="_${ctx}__"
    dt_debug ${fname} "${BOLD}INIT CTX${RESET}: ctx=${ctx}"
    ${ctx}
    dt_debug ${fname} "${BOLD}CONTINUE LOAD${RESET}: ctx=${ctx}"
    vars=$(eval echo "\${vars_${ctx}}")
    if [ -n "${filter}" ]; then
      vars=("${filter[@]}")
    else
      vars=($(eval echo "\${${vars}[@]}"))
    fi
    for var in ${vars[@]}; do
      val=$(eval echo "\$${prefix}${var}")
      dt_debug ${fname} "loop: prefix=${prefix}, var=${var}, val=${val}"
      if [ -z "${val}" ]; then
        dt_warning ${fname} "Var ${BOLD}${var}${RESET} is ${BOLD}empty${RESET}"
      fi
      remapped="n"
      _remap; err=$?
      if [ "${err}" != 0 ]; then dt_error ${fname} "Error while remapping: err=${err}"; return "${err}"; fi
      if [ "${remapped}" = "n" ]; then
        dt_debug ${fname} "ctx=${ctx}: ${BOLD}loading${RESET} var ${BOLD}${var}${RESET}=${val}"
        eval "${var}=\$${prefix}${var}"
        vname=${var}
      fi
      _export && _unexport; err=$?
      if [ "${err}" != 0 ]; then dt_error ${fname} "Error while export/unexport: err=${err}"; return "${err}"; fi
    done
  done
  dt_debug ${fname} "${BOLD}EXIT${RESET}"
}
