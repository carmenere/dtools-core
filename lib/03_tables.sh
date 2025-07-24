get_var_args() {
  local wait fname=$(fname "${FUNCNAME[0]}" "$0")
  while [ "$#" -gt 0 ];
  do
    case $1 in
      -r|--record)
        wait=$1
        dt_debug ${fname} "wait=${wait}"
        shift
        ;;
      -t|--table)
        wait=$1
        dt_debug ${fname} "wait=${wait}"
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
  dt_debug ${fname} "tbl=${tbl}, rec=${rec}"
}

set_tbl() { DT_TABLE="$1"; }
set_rec() { DT_RECORD="$1"; }

tbl_name() { echo "tbl_$1"; }
rec_name() { echo "$(echo "$1" | sed -e 's/:/_/g')"; }
# get name of parent rec
rec_parent() { parent=$(rec_name "$(echo "$1" | awk -F':' 'OFS=":" {NF=NF-1; print $0}')"); }

fqn_rec() { echo "$1__$2"; }
fqn_var() { echo "$1__$2__$3"; }

# rec: mandatory
# tbl: optional
get_rec() {
  local table record rec=$1 tbl=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${rec}" ]; then
    record=$(rec_name ${rec})
  else
    if [ -z "${DT_RECORD}" ]; then
      dt_error ${fname} "Record name was not provided: arg ${BOLD}rec${RESET} and var ${BOLD}DT_RECORD${RESET} are both empty"
      return 99
    else
      record=${DT_RECORD}
    fi
  fi
  table=$(get_table ${tbl}) && \
  fq_rec=$(fqn_rec ${table} ${record}) && \
  if ! declare -p "${fq_rec}" >/dev/null 2>&1; then
    dt_error ${fname} "Record ${BOLD}${fq_rec}${RESET} doesn't exist"
    return 99
  fi && \
  echo "${record}"
}

get_table() {
  local table tbl=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${tbl}" ]; then
    table=$(tbl_name "${tbl}")
  else
    if [ -z "${DT_TABLE}" ]; then
      dt_error ${fname} "Table name was not provided: arg ${BOLD}tbl${RESET} and var ${BOLD}DT_TABLE${RESET} are both empty"
      return 99
    else
      table=${DT_TABLE}
    fi
  fi
  if ! declare -p "${table}" >/dev/null 2>&1; then
    dt_error ${fname} "Table ${BOLD}${table}${RESET} doesn't exist"
    return 99
  fi
  echo "${table}"
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
  table=$(tbl_name "${tbl}") && \
  if ! declare -p "${table}" >/dev/null 2>&1; then
    eval "${table}=" && \
    DT_VARS+=("${table}") || return $?
  fi && \
  set_tbl "${table}"
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
    parent=$(rec_name "$2")
    shift 2
    if ! declare -p "${parent}" >/dev/null 2>&1; then dt_error ${fname} "Provided parent record ${BOLD}${parent}${RESET} doesn't exist"; return 99; fi
  fi
  if [ -n "$1" ]; then dt_error ${fname} "Unexpected parameter: $1"; return 99; fi
}

record() {
  local mergefunc table parent fq_rec rec="$1" fname=$(fname "${FUNCNAME[0]}" "$0")
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
    if [ -z "${parent}" ]; then
      parent=$(rec_parent "${rec}") && \
      parent="$(get_rec "${parent}")" || return $?
    else
      parent="$(get_rec "${parent}")" || return $?
    fi && \
    if [ -z "${parent}" ]; then
      dt_error ${fname} "Nor merge function neither parent was provided"
      return 99
    fi && \
    fq_rec_parent=$(fqn_rec "${table}" "${parent}") && \
    mergefunc="$(eval echo "\$${fq_rec_parent}_merge")" && \
    if [ -z "${mergefunc}" ]; then
      dt_error ${fname} "Cannot find merge function"
      return 99
    fi
  fi && \
  DT_VARS+=("${fq_rec}") && \
  DT_VARS+=("${fq_rec}_merge") && \
  DT_VARS+=("${fq_rec}_parent") && \
  eval "${fq_rec}=" && \
  eval "${fq_rec}_parent=${parent}" && \
  eval "${fq_rec}_merge=${mergefunc}" && \
  set_rec "${rec}"
}

merge() {
  local DT_PARENT mergefunc table record parent fq_rec fname=$(fname "${FUNCNAME[0]}" "$0")
  table=$(get_table) && \
  rec="$(get_rec "${DT_RECORD}")" && \
  fq_rec=$(fqn_rec "${table}" "${rec}") && \
  if declare -p "${fq_rec}_merged" >/dev/null 2>&1; then
    dt_error ${fname} "Record ${BOLD}${fq_rec}${RESET} has already merged"
    return 99
  fi && \
  DT_PARENT="$(eval echo "\$${fq_rec}_parent")" && \
  mergefunc="$(eval echo "\$${fq_rec}_merge")" && \
  if [ -z "${DT_PARENT}" ] && [ -z "${mergefunc}" ]; then
    dt_error ${fname} "Nor merge function neither parent was provided"
    return 99
  fi && \
  dt_debug ${fname} "Merge function is ${BOLD}${mergefunc}${RESET}, parent=${DT_PARENT}" && \
  ${mergefunc} && \
  eval "${fq_rec}_merged=yes" && \
  DT_VARS+=("${fq_rec}_merged")
}

merge_docker_network() {
  mvar SUBNET "192.168.111.0/24"
  mvar BRIDGE "example"
  mvar DRIVER "bridge"
}

merge_docker_refs() {
  local DT_SCTX=refs
  mvar net docker_network_default
  mvar conn pg_conn_admin
}

merge_docker_image() {
  local DT_SCTX=image
  mvar BASE_IMAGE "$(docker_arm64v8)alpine:3.22.1"
  mvar BUILD_ARGS
  mvar BUILD_VERSION "$(git_build_version)"
  mvar CTX "."
  mvar DEFAULT_TAG $(docker_default_tag)
  mvar IMAGE $(BASE_IMAGE)
}

merge_docker_service() {
  local DT_SCTX=service
  mvar CHECK "docker_check"
  mvar COMMAND
  mvar EXEC "docker_exec_i_cmd"
  mvar FLAGS "-d"
  mvar PUBLISH
  mvar RESTART "always"
  mvar RM
  mvar RUN_ENVS
  mvar SERVICE
  mvar SH "/bin/sh"
  mvar TERMINAL "docker_exec_it_cmd"
  mvar BRIDGE $(BRIDGE $(net :refs))
}

merge_docker_publish() {
  local DT_SCTX=publish
  mvar PORT 5432
  mvar PUB_PORT $(PORT $(conn :refs):docker)
  mvar PUBLISH "$(PUB_PORT):$(PORT)/tcp"
}

merge_docker() {
  merge_docker_refs
  merge_docker_image
  merge_docker_service
  merge_docker_publish
}


merge_test() {
  echo "Will merge $1 with its parent $2"
}

#merge_docker_run_envs_pg() {
#  local DT_TABLE= DT_PCTX= prefix="ctx_docker_image" fname=$(fname "${FUNCNAME[0]}" "$0")
#  DT_TABLE=$(set_ctx_prefix $1) && err_if_empty ${fname} "DT_TABLE"
#  DT_PCTX=$(set_pctx_prefix $2)
#  var pg_conn pg_conn_default
#  mvar RUN_ENVS "POSTGRES_PASSWORD POSTGRES_DB POSTGRES_USER"
#  mvar POSTGRES_PASSWORD "$(pg_conn PGPASSWORD )"
#  mvar POSTGRES_DB "$(pg_conn PGDATABASE )"
#  mvar POSTGRES_USER "$(pg_conn PGUSER )"
#}

merge_conn() {
  mvar USER $(pg_superuser)
  mvar PASSWORD "postgres"
  mvar DATABASE "postgres"
  mvar HOST "localhost"
  mvar PORT 0
}

merge_socket() {
  mvar PORT 0
  mvar HOST "localhost"
  mvar PROTO "tcp"
}
