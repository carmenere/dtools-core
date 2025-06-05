inited_ctxes=()

# Example: dt_ctx_is_initialized "${ctx}"; err=$?
# if [ "${err}" = 99 ]; then
#   return $?
# elif [ "${err}" = 10 ]; then
#   dt_debug "${ctx} has already been inited, skip"
#   return 0
# fi
function dt_ctx_is_initialized() {
  ctx="$1"; rezult=
  if [ -z ${ctx} ]; then dt_error ${fname} "ctx was not provided."; return 99; fi
  for c in "${inited_ctxes[@]}";  do
    if [ "${c}" = "${ctx}" ]; then
      rezult="${ctx}"
      return 10
    fi
  done
}

# Consider function docker_build()
# dt_register ctx_conn_docker_pg_admin pg docker_methods
# will generate function docker_build_pg() { dt_init_and_load_ctx && docker_build_pg }
function dt_register() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local ctx=$1; dt_err_if_empty ${fname} "ctx" "${ctx}"
  err=$?; if [ "${err}" != 0 ]; then dt_error ${fname} "err=${err}"; return ${err}; fi
  local suffix=$2; dt_err_if_empty ${fname} "suffix" "${suffix}"
  err=$?; if [ "${err}" != 0 ]; then dt_error ${fname} "err=${err}"; return ${err}; fi
  shift 2
  local methods=("$@"); dt_err_if_empty ${fname} "methods" "${methods}"
  err=$?; if [ "${err}" != 0 ]; then dt_error ${}fnam}e "err=${err}"; return ${err}; fi
  for method in ${methods[@]}; do
    local func=${method}_${suffix}
    eval "function ${func}() { ${method} ${ctx} }"
  done
}

function _dt_init_ctx() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "${init}" = "y" ]; then
     dt_ctx_is_initialized "${ctx}"; err=$?
     if [ "${err}" = 99 ]; then
       return $?
     elif [ "${err}" = 10 ]; then
       dt_debug ${fname} "ctx '${BOLD}${ctx}${RESET}' has already been initialized, ${BOLD}skip${RESET}"
       return 0
     fi
     dt_info ${fname} "initializing ctx '${ctx}' ..."
     ${ctx}
  fi
}

function _dt_parse_ctxes() {
  local fname opt OPTSTRING OPTIND OPTARG
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  OPTSTRING=":ic:v:m:"
  while getopts ${OPTSTRING} opt; do
    case ${opt} in
      c) if [ "${OPTARG:0:1}" = "-" ]; then
           dt_error "Option ${opt} requires an argument, but got another option '-${OPTARG}' instead value."
           return 99
         fi
         dt_debug ${fname} "adding ctx '${OPTARG}'"
         ctxes+=(${OPTARG});;
      i) if [ "${OPTARG:0:1}" = "-" ]; then
            dt_error "Option ${opt} requires an argument, but got another option '-${OPTARG}' instead value."
            return 99
          fi
          dt_debug ${fname} "setting 'init' flag"
          init="y";;
      v)  if [ "${OPTARG:0:1}" = "-" ]; then
            dt_error "Option ${opt} requires an argument, but got another option '-${OPTARG}' instead value."
            return 99
          fi
          dt_debug ${fname} "adding variable '${OPTARG}'"
          filter+=(${OPTARG});;
      m) if [ "${OPTARG:0:1}" = "-" ]; then
           dt_error "Option ${opt} requires an argument, but got another option '-${OPTARG}' instead value."
           return 99
         fi
         dt_debug ${fname} "adding mapping '${OPTARG}'"
         map+=(${OPTARG});;
      :) echo "Option -${OPTARG} requires an argument."; return 99;;
      ?) echo "Invalid option: '-${OPTARG}'."; return 1;;
    esac
  done
}

# -m FOO=>B -m BAR=>X: rename vars during loading
# -v FOO -v BAR: list of vars to be loaded, if empty - all vars of all ctxes will be loaded
# -c %ctx_name%: contains name of ctx and can be used multiple times
# -i: every ctx is callable, if the option "-i" is passed then ecah %ctx_name% in the array ctxes will be called
function dt_load_ctx() {
  local ctxes filter init map ctx vars var val fname remapped
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctxes=()
  filter=()
  init="n"
  map=()
  _dt_parse_ctxes $@; err=$?
  if [ "${err}" != 0 ]; then dt_error ${fname} "Error while parsing args: err=${err}"; return ${err}; fi
  dt_debug ${fname} "ctxes='${ctxes}', filter='${filter}', init=${init}, map='${map}'"
  for ctx in ${ctxes[@]}; do
    dt_debug ${fname} "ctx=${ctx}"
    _dt_init_ctx
    vars=$(eval echo "\${vars_${ctx}}")
    if [ -n "${filter}" ]; then
      vars=("${filter[@]}")
    else
      vars=($(eval echo "\${${vars}[@]}"))
    fi
    for var in ${vars[@]}; do
      val=$(eval echo "\$${ctx}__${var}")
      if [ -z "${val}" ]; then
        dt_warning ${fname} "Var ${BOLD}${var}${RESET} is ${BOLD}empty${RESET}"
      fi
      remapped="n"
      for pair in "${map[@]}";  do
        old=$(echo ${pair} | sed -E -e "s/^(.+)=>.+$/\1/")
        new=$(echo ${pair} | sed -E -e "s/^.+=>(.+)$/\1/")
        if [ "${old}" = "${var}" ]; then
          dt_debug ${fname} "${BOLD}match${RESET} var=${BOLD}${var}${RESET}, old=${BOLD}${old}${RESET}, new=${new}"
          dt_debug ${fname} "ctx=${ctx}: loading ${BOLD}remapped${RESET} var ${BOLD}${new}${RESET}=${val}"
          eval "${new}=\$${ctx}__${var}"
          remapped="y"
          break
        fi
      done
      if [ "${remapped}" = "n" ]; then
        dt_debug ${fname} "ctx=${ctx}: loading var ${BOLD}${var}${RESET}=${val}"
        eval "${var}=\$${ctx}__${var}"
      fi
    done
  done
}

function dt_set_ctx() {
  local vars val var ctx fname
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; shift
  vars=$(eval echo "\${vars_${ctx}}")
  for var in $(eval echo "\${${vars}[@]}"); do
    val=$(eval echo "\$${var}")
    dt_debug ${fname} "ctx=${ctx}: setting var ${BOLD}${var}${RESET}=${val}"
    if [ -z "${val}" ]; then
      dt_warning ${fname} "Var ${BOLD}${var}${RESET} is ${BOLD}empty${RESET}"
    fi
    eval "${ctx}__${var}=\"${val}\""
  done
  inited_ctxes+=(${ctx})
}

# -c %ctx_name%: contains name of ctx and can be used multiple times
# -i: every ctx is callable, if the option "-i" is passed then ecah %ctx_name% in the array ctxes will be called
function dt_export() {
  local init ctxes ctx vars var val fname
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctxes=()
  init="n"
  _dt_parse_ctxes $@
  dt_debug ${fname} "ctxes=${ctxes[@]}, init=${init}"
  for ctx in ${ctxes[@]}; do
    dt_debug ${fname} "ctx=${ctx}"
    _dt_init_ctx
    vars=$(eval echo "\${vars_${ctx}}")
    for var in $(eval echo "\${${vars}[@]}"); do
      dt_debug ${fname} "var=${var}"
      val=$(eval echo \"\$${ctx}__${var}\")
      dt_exec "export ${ctx}__${var}=\"${val}\""
    done
  done
}

function dt_unexport() {
  local ctxes ctx vars var val fname
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctxes=()
  _dt_parse_ctxes $@
  dt_debug ${fname} "ctxes=${ctxes[@]}"
  for var in ${vars[@]}; do
    for ctx in ${ctxes[@]}; do
      dt_exec "unset ${ctx}__${var}"
    done
  done
}