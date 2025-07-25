# wait="fq" - here "fq" means fully qualified, e.g. table_name:record_name
get_var_args() {
  local wait="fq" fname=$(fname "${FUNCNAME[0]}" "$0")
  while [ "$#" -gt 0 ];
  do
    case $1 in
      -r|--record)
        wait=$1
        shift
        ;;
      -t|--table)
        wait=$1
        shift
        ;;
      *)
        if [ -z "${wait}" ]; then dt_error ${fname} "Unexpected positional parameter: $1."; return 99; fi
        if [ -z "$1" ]; then dt_error ${fname} "Empty value for option ${wait}"; return 99; fi
        case ${wait} in
          -r|--record)
            rec=$1
            wait=
            shift
            ;;
          -t|--table)
            tbl=$1
            wait=
            shift
            ;;
          fq)
            tbl=$(echo "$1" | awk -F':' '{print $1}')
            rec=$(echo "$1" | awk -F':' '{print $2}')
            wait=
            shift
            ;;
          *)
            dt_error ${fname} "Invalid state of parser: wait=${wait}."; return 99;
            ;;
        esac
        ;;
    esac
  done
}

set_tbl() { DT_TABLE="$1"; }
set_rec() { DT_RECORD="$1"; }

tbl_name() { echo "tbl_$1"; }
#rec_name() { echo "$(echo "$1" | sed -e 's/:/_/g')"; }
# remove last item in line
#echo "$1" | awk -F':' 'OFS=":" {NF=NF-1; print $0}'

fqn_rec() { echo "tbl_$1__$2"; }
fqn_var() { echo "tbl_$1__$2__$3"; }

# Checks that record $rec (if $rec is empty uses $DT_RECORD) exists and returns current record back
# rec: mandatory
# tbl: optional
get_rec() {
  local record rec=$1 tbl=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "${rec}" ]; then
    if [ -z "${DT_RECORD}" ]; then
      dt_error ${fname} "Record name was not provided: arg ${BOLD}rec${RESET} and var ${BOLD}DT_RECORD${RESET} are both empty"
      return 99
    else
      rec=${DT_RECORD}
    fi
  fi && \
  tbl=$(get_table ${tbl}) && \
  fq_rec=$(fqn_rec ${tbl} ${rec}) && \
  dt_debug ${fname} "rec=${rec}, fq_rec=${BOLD}${fq_rec}${RESET}, tbl=${tbl}" && \
  if ! declare -p "${fq_rec}" >/dev/null 2>&1; then
    dt_error ${fname} "Record ${BOLD}${fq_rec}${RESET} doesn't exist"
    return 99
  fi
  echo "${rec}"
}

# Adds tbl_prefix to tbl checks that such table exists and returns prefixed value: tbl_${tbl}
get_table() {
  local table tbl=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "${tbl}" ]; then
    if [ -z "${DT_TABLE}" ]; then
      dt_error ${fname} "Table name was not provided: arg ${BOLD}tbl${RESET} and var ${BOLD}DT_TABLE${RESET} are both empty"
      return 99
    else
      tbl="${DT_TABLE}"
    fi
  fi
  table=$(tbl_name "${tbl}")
  if ! declare -p "${table}" >/dev/null 2>&1; then
    dt_error ${fname} "Table ${BOLD}${table}${RESET} doesn't exist"
    return 99
  fi
  echo "${tbl}"
}

# get value of variable "var" of some record "rec" of some table "tbl"
# rec: optional
# tbl: optional
get_var() {
  local tbl val rec var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift; get_var_args $@ && \
  dt_debug ${fname} "tbl=${tbl}, rec=${rec}" && \
  tbl="$(get_table "${tbl}")" && \
  rec="$(get_rec "${rec}" "${tbl}")" && \
  fq_var=$(fqn_var "${tbl}" "${rec}" "${var}") && \
  if declare -p "${fq_var}" >/dev/null 2>&1; then
    val="$(eval echo "\$${fq_var}")" && \
    echo "${val}" || return $?
  else
    dt_error ${fname} "Variable ${BOLD}${fq_var}${RESET} doesn't exist"
    return 99
  fi
}

# resets variable "var" in some ctx DT_TABLE
# ovar: original name of some variable "var" without prefix
var() {
  local val tbl rec fq_var var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift; val="$*" && \
  tbl=$(get_table) && \
  rec=$(get_rec) && \
  err_if_empty ${fname} "var" && \
  fq_var=$(fqn_var "${tbl}" "${rec}" "${var}") && \
  local msg_tmpl="${BOLD}${fq_var}${RESET} to value '${BOLD}${val}${RESET}'" && \
  if declare -p ${fq_var} >/dev/null 2>&1; then
    dt_warning ${fname} "Resetting ${msg_tmpl}"
  else
    dt_debug ${fname} "Setting ${msg_tmpl}"
    DT_VARS+=("${fq_var}")
    eval "${var}() { get_var ${var} \$1 \$2 \$3 \$4; }" || return $?
  fi && \
  local nval="$(escape_quote "${val}")" && \
  eval "${fq_var}=$'${nval}'"
}

# merges var in parent record DT_PARENT and with one in current DT_TABLE
mvar() {
  local val pval tbl rec fq_var var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift; pval="$*" && \
  err_if_empty ${fname} "var" && \
  tbl=$(get_table) && \
  rec=$(get_rec) && \
  fq_var=$(fqn_var "${tbl}" "${rec}" "${var}") && \
  if declare -p ${fq_var} >/dev/null 2>&1; then
    val="$(eval echo \$${fq_var})" || return $?
    dt_debug ${fname} "Skip merge for var ${BOLD}${fq_var}${RESET}: it has already set and its value is '${BOLD}${val}${RESET}'"
    return 0
  fi && \
  dt_debug ${fname} "Merging var ${BOLD}${fq_var}${RESET} with parent ctx '${BOLD}${DT_PARENT}${RESET}'" && \
  if [ -z "${DT_PARENT}" ]; then
    var "${var}" "${pval}" || return $?
  else
    rec=$(get_rec "${DT_PARENT}") && \
    pval="$(${var} -t "${tbl}" -r "${rec}")" && \
    var "${var}" "${pval}" || return $?
  fi
}

# merges ref in parent record DT_PARENT and with one in current DT_TABLE
mref() {
  local val pval tbl parent_rec rec fq_var var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift; ref_tbl=$1 ref_rec="$2"
  err_if_empty ${fname} "var" && \
  tbl=$(get_table) && \
  rec=$(get_rec) && \
  fq_var=$(fqn_var "${tbl}" "${rec}" "${var}") && \
  dt_debug ${fname} "fq_var=${BOLD}${fq_var}${RESET}" && \
  if declare -p ${fq_var} >/dev/null 2>&1; then
    val="$(eval echo \$${fq_var})" || return $?
    dt_debug ${fname} "Adding prefix ${ref_tbl} to record ${BOLD}${val}${RESET}, fq_var=${BOLD}${fq_var}${RESET}"
    var "${var}" "${ref_tbl}:${val}" || return $?
    return 0
  fi && \
  dt_debug ${fname} "Merging var ${BOLD}${fq_var}${RESET} with parent ctx '${BOLD}${DT_PARENT}${RESET}'" && \
  if [ -z "${DT_PARENT}" ]; then
    var "${var}" "${ref_tbl}:${ref_rec}" || return $?
  else
    parent_rec=$(get_rec "${DT_PARENT}") && \
    pval=$(${var} -t "${tbl}" -r "${parent_rec}") && \
    var "${var}" "${pval}" || return $?
  fi
}

table() {
  local mergefunc table tbl=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${DT_RECORD}" ]; then dt_debug ${fname} "Will merge record ${BOLD}${DT_RECORD}${RESET}"; merge; DT_RECORD=; fi
  table=$(tbl_name "${tbl}") && \
  dt_debug ${fname} "${BOLD}New table=${table}${RESET}" && \
  if ! declare -p "${table}" >/dev/null 2>&1; then
    eval "${table}=" && \
    set_tbl "${tbl}" && \
    DT_TABLES+=("${tbl}") && \
    DT_VARS+=("${table}") && \
    DT_VARS+=("records_${tbl}") || return $?
  else
    set_tbl "${tbl}"
  fi
}

# -m and -p are mutually exclusive, so there is no need for more complex logic like in get_var_args
record_args() {
  if [ "$1" = "-m" ]; then
    if [ -z $2 ]; then dt_error ${fname} "Merge function was not provided"; return 99; fi
    mergefunc="merge_$2"
    shift 2
    if ! declare -f "${mergefunc}" >/dev/null 2>&1; then dt_error ${fname} "Provided merge function ${BOLD}${mergefunc}${RESET} doesn't exist"; return 99; fi
  elif [ "$1" = "-p" ]; then
    if [ -z $2 ]; then dt_error ${fname} "Parent was not provided"; return 99; fi
    parent="$2"
    shift 2
#    if ! declare -p "${parent}" >/dev/null 2>&1; then dt_error ${fname} "Provided parent record ${BOLD}${parent}${RESET} doesn't exist"; return 99; fi
  fi
  if [ -n "$1" ]; then dt_error ${fname} "Unexpected parameter: $1"; return 99; fi
}

record() {
  local mergefunc tbl parent fq_rec rec="$1" fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${DT_RECORD}" ]; then dt_debug ${fname} "Will merge record ${BOLD}${DT_RECORD}${RESET}"; merge; fi
  dt_debug ${fname} "${BOLD}New record=${rec}${RESET}" && \
  err_if_empty ${fname} "rec" && \
  shift && record_args $@ && \
  tbl=$(get_table) && \
  fq_rec=$(fqn_rec "${tbl}" "${rec}") || return $?
  if declare -p "${fq_rec}" >/dev/null 2>&1; then
    dt_error ${fname} "Record ${BOLD}${fq_rec}${RESET} already exists"
    return 99
  fi && \
  dt_debug ${fname} "rec=${rec}, parent=${parent}, mergefunc=${mergefunc}" && \
  if [ -z "${mergefunc}" ]; then
    if [ -n "${parent}" ]; then
      parent="$(get_rec "${parent}")" || return $?
    else
      dt_error ${fname} "Nor merge function neither parent was provided"
      return 99
    fi && \
    fq_rec_parent=$(fqn_rec "${tbl}" "${parent}") && \
    mergefunc="$(eval echo "\$${fq_rec_parent}__merge")" && \
    if [ -z "${mergefunc}" ]; then
      dt_error ${fname} "Cannot find merge function"
      return 99
    fi
  fi && \
  DT_VARS+=("${fq_rec}") && \
  DT_VARS+=("${fq_rec}__merge") && \
  DT_VARS+=("${fq_rec}__parent") && \
  eval "${fq_rec}=" && \
  eval "${fq_rec}__parent=${parent}" && \
  eval "${fq_rec}__merge=${mergefunc}" && \
  eval "records_${tbl}+=(${rec})" && \
  set_rec "${rec}"
}

merge() {
  local DT_PARENT mergefunc tbl rec fq_rec fname=$(fname "${FUNCNAME[0]}" "$0")
  tbl=$(get_table) && \
  rec="$(get_rec "${DT_RECORD}")" && \
  dt_debug ${fname} "tbl=${tbl}, rec=${rec}" && \
  fq_rec=$(fqn_rec "${tbl}" "${rec}") && \
  dt_debug ${fname} "fq_rec=${BOLD}${fq_rec}${RESET}" && \
  if declare -p "${fq_rec}__merged" >/dev/null 2>&1; then
    dt_error ${fname} "Record ${BOLD}${fq_rec}${RESET} has already merged"
    return 99
  fi && \
  DT_PARENT="$(eval echo "\$${fq_rec}__parent")" && \
  mergefunc="$(eval echo "\$${fq_rec}__merge")" && \
  dt_debug ${fname} "rec=${BOLD}${rec}${RESET} parent_rec=${BOLD}${DT_PARENT}${RESET}, mergefunc=${BOLD}${mergefunc}${RESET}" && \
  if [ -z "${DT_PARENT}" ] && [ -z "${mergefunc}" ]; then
    dt_error ${fname} "Nor merge function neither parent was provided"
    return 99
  fi && \
  dt_debug ${fname} "Merge function is ${BOLD}${mergefunc}${RESET}, parent=${DT_PARENT}" && \
  ${mergefunc} && \
  eval "${fq_rec}__merged=yes" && \
  DT_VARS+=("${fq_rec}__merged")
}
