#function _check_optarg() {
#  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
#  if [ "${OPTARG:0:1}" = "-" ]; then
#    dt_error ${fname} "Option ${opt} requires an argument, but got another option '-${OPTARG}' instead value."
#    return 99
#  fi
#}

#function _dt_parse_ctxes() {
#  local fname opt OPTSTRING OPTIND OPTARG
#  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
#  OPTSTRING=":c:v:m:eu"
#  while getopts ${OPTSTRING} opt; do
#    dt_debug ${fname} "${BOLD}ID=${id}${RESET}: opt=${opt}, OPTARG=${OPTARG}"
#    case ${opt} in
#      c) _check_optarg || return $?; ctxes+=(${OPTARG});;
#      v) _check_optarg || return $?; filter+=(${OPTARG});;
#      m) _check_optarg || return $?; map+=(${OPTARG});;
#      e) _check_optarg || return $?; export="y";;
#      u) _check_optarg || return $?; unexport="y";;
#      :) echo "Option -${OPTARG} requires an argument."; return 88;;
#      ?) echo "Invalid option: '-${OPTARG}'."; return 99;;
#    esac
#  done
#}

# Usage: dt_export ctx_service_pg_tetrix
function dt_export() {
  local fname ctx prf
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  prf=$(var_prf ${ctx})
  . <(env | while read var; do
    awk -v prf="${prf}" -F'=' '{ if ($1 ~ prf) { sub(prf,"", $1); printf "export %s=\"%s\"\n", $1, $2 } }'
  done)
}

# Usage: dt_unexport ctx_service_pg_tetrix
function dt_unexport() {
  local fname ctx prf
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  prf=$(var_prf $1)
  . <(env | while read var; do
    awk -v prf="${prf}" -F'=' '{ if ($1 ~ prf) { sub(prf,"", $1); printf "unset %s\n", $1 } }'
  done)
}

# Usage: clone_ctx ctx_service_pg ctx_service_pg_tetrix
function clone_ctx() {
  local fname ctx oprf nprf
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  octx=$1; dt_err_if_empty ${fname} "octx" || return $?
  nctx=$1; dt_err_if_empty ${fname} "nctx" || return $?
  oprf=$(var_prf ${octx})
  nprf=$(var_prf ${nprf})
  . <(env | while read var; do
    awk -v old="${oprf}" -v new="${nprf}" -F'=' '{ if ($1 ~ old) { sub(old,"", $1); printf "export %s%s=\"%s\"\n", new, $1, $2 } }'
  done)
}

function drop_ctx() {
  local fname ctx
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  dt_debug ${fname} "${ctx}"
  prf=$(var_prf ${ctx})
  . <(env | while read var; do
    awk -v prf="${prf}" -F'=' '{ if ($1 ~ prf) { printf "unset %s\n", $1 } }'
  done)
}
