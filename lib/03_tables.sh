# autocomplete_%TBL% - custom autocomplete function
# %TBL%_records - record names, will be used as words for autocomplete
# %TBL%_methods - methods to be bound to autocomplete_%TBL%

dt_autocomplete() {
  local methods autocomplete
  methods=$1_methods
  autocomplete=autocomplete_$1
  methods=($(echo "$(${methods})"))
  [ -n "$2" ] && pref="$2 "
  result=()
  for m in ${methods[@]}; do
    echo "complete -F ${autocomplete} ${m}"
    complete -F ${autocomplete} ${m}
  done
}

docker_image_autocomplete=()
docker_image_autocomplete+=("pg")
docker_image_autocomplete+=("pg_docker")
docker_image_autocomplete+=("pg_tetrix")
docker_image_autocomplete+=("pg_docker_tetrix")

autocomplete_docker_image() {
  local cur_word="${COMP_WORDS[COMP_CWORD]}"
  local options="${docker_image_records[@]}" # Example options
  COMPREPLY=( $(compgen -W "${options}" -- "${cur_word}") )
}

docker_build() {
  echo "docker_build $1"
}

docker_pull() {
  echo "docker_build $1"
}

docker_image_methods() {
  local methods=()
  methods+=(docker_build)
  methods+=(docker_pull)
  echo "${methods[@]}"
}

dt_autocomplete docker_image

get_var_args() {
  local wait fname=$(fname "${FUNCNAME[0]}" "$0")
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
## get name of parent rec
#rec_parent() { parent=$(rec_name "$(echo "$1" | awk -F':' 'OFS=":" {NF=NF-1; print $0}')"); }

fqn_rec() { echo "tbl_$1__$2"; }
fqn_var() { echo "tbl_$1__$2__$3"; }

# Checks that record $rec (if $rec is empty uses $DT_RECORD) exists and returns current record back
# rec: mandatory
# tbl: optional
get_rec() {
  local table record rec=$1 tbl=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "${rec}" ]; then
    if [ -z "${DT_RECORD}" ]; then
      dt_error ${fname} "Record name was not provided: arg ${BOLD}rec${RESET} and var ${BOLD}DT_RECORD${RESET} are both empty"
      return 99
    else
      rec=${DT_RECORD}
    fi
  fi && \
  table=$(get_table ${tbl}) && \
  fq_rec=$(fqn_rec ${table} ${rec}) && \
  dt_debug ${fname} "rec=${rec}, fq_rec=${BOLD}${fq_rec}${RESET}, table=${table}" && \
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
  local table val rec tbl var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift; get_var_args $@ && \
  dt_debug ${fname} "tbl=${tbl}, rec=${rec}" && \
  table="$(get_table "${tbl}")" && \
  rec="$(get_rec "${rec}")" && \
  fq_var=$(fqn_var "${table}" "${rec}" "${var}") && \
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
  local val table rec fq_var var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift; val="$*" && \
  table=$(get_table) && \
  rec=$(get_rec) && \
  err_if_empty ${fname} "var" && \
  fq_var=$(fqn_var "${table}" "${rec}" "${var}") && \
  local msg_tmpl="${BOLD}${fq_var}${RESET} to value '${BOLD}${val}${RESET}'" && \
  if declare -p ${fq_var} >/dev/null 2>&1; then
    dt_warning ${fname} "Resetting ${msg_tmpl}"
  else
    dt_debug ${fname} "Setting ${msg_tmpl}"
    DT_VARS+=("${fq_var}")
    eval "${var}() { get_var ${var} \$1 \$2 \$3 \$4; }" || return $?
  fi && \
  eval "${fq_var}=\"${val}\""
}

# merges var in parent ctx DT_PARENT and with one in ctx DT_TABLE
# ovar: original name of some variable "var" without prefix
mvar() {
  local val pval table rec fq_var var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift; pval="$*"
  err_if_empty ${fname} "var" && \
  table=$(get_table) && \
  rec=$(get_rec) && \
  fq_var=$(fqn_var "${table}" "${rec}" "${var}") && \
  dt_debug ${fname} "fq_var=${BOLD}${fq_var}${RESET}" && \
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
    pval=$(${var} -t "${table}" -r "${rec}") && \
    var "${var}" "${pval}" || return $?
  fi
}

table() {
  local mergefunc table tbl=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${DT_RECORD}" ]; then dt_debug ${fname} "Will merge record ${BOLD}${DT_RECORD}${RESET}"; merge; DT_RECORD=; fi
  table=$(tbl_name "${tbl}") && \
  if ! declare -p "${table}" >/dev/null 2>&1; then
    eval "${table}=" && \
    DT_VARS+=("${table}") || return $?
  fi && \
  set_tbl "${tbl}"
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
  local mergefunc table parent fq_rec rec="$1" fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${DT_RECORD}" ]; then dt_debug ${fname} "Will merge record ${BOLD}${DT_RECORD}${RESET}"; merge; fi
  err_if_empty ${fname} "rec" && \
  shift && record_args $@ && \
  table=$(get_table) && \
  fq_rec=$(fqn_rec "${table}" "${rec}") || return $?
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
    fq_rec_parent=$(fqn_rec "${table}" "${parent}") && \
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
  set_rec "${rec}"
}

merge() {
  local DT_PARENT mergefunc table rec fq_rec fname=$(fname "${FUNCNAME[0]}" "$0")
  table=$(get_table) && \
  rec="$(get_rec "${DT_RECORD}")" && \
  dt_debug ${fname} "table=${table}, DT_RECORD=${DT_RECORD}, rec=${rec}"
  fq_rec=$(fqn_rec "${table}" "${rec}") && \
  dt_debug ${fname} "fq_rec=${BOLD}${fq_rec}${RESET}"
  if declare -p "${fq_rec}__merged" >/dev/null 2>&1; then
    dt_error ${fname} "Record ${BOLD}${fq_rec}${RESET} has already merged"
    return 99
  fi && \
  DT_PARENT="$(eval echo "\$${fq_rec}__parent")" && \
  mergefunc="$(eval echo "\$${fq_rec}__merge")" && \
  dt_debug ${fname} "DT_PARENT=${DT_PARENT}, mergefunc=${mergefunc}"
  if [ -z "${DT_PARENT}" ] && [ -z "${mergefunc}" ]; then
    dt_error ${fname} "Nor merge function neither parent was provided"
    return 99
  fi && \
  dt_debug ${fname} "Merge function is ${BOLD}${mergefunc}${RESET}, parent=${DT_PARENT}" && \
  ${mergefunc} && \
  eval "${fq_rec}__merged=yes" && \
  DT_VARS+=("${fq_rec}__merged")
}
