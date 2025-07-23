set_tbl() { DT_TABLE="$1"; }
set_rec() { DT_RECORD="$1"; }

tbl_name() { echo "tbl_$1"; }
rec_name() { echo "$(echo "$1" | sed -e 's/:/_/g')"; }
rec_fqn() { echo "$1__$2"; }
var_fqn() { echo "$1__$2__$3"; }

get_record() {
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
  fq_rec=$(rec_fqn ${table} ${record}) && \
  if ! declare -p "${fq_rec}" >/dev/null 2>&1; then
    dt_error ${fname} "Record ${BOLD}${fq_rec}${RESET} doesn't exist"
    return 99
  fi && \
  echo "${record}"
}

get_table() {
  local table tbl=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -n "${tbl}" ]; then
    table=$(tbl_name ${tbl})
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
get_var() {
  local table val rec tbl var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift
  if [ "$1" = "-r" ]; then
    rec="$2"
  elif [ "$1" = "-t" ]; then
    tbl="$2"
  else
    dt_error ${fname} "Unknown args"; return 99
  fi
  table="$(get_table ${tbl})" && \
  record="$(rec_name ${rec})" && \
  fq_var=$(var_fqn ${table} ${record} ${var}) || return $?
  if declare -p ${fq_var} >/dev/null 2>&1; then
    val=$(eval echo \$${fq_var})
    echo "${val}"
  else
    dt_error ${fname} "Variable ${BOLD}${fq_var}${RESET} doesn't exist"
    return 99
  fi
}

# resets variable "var" in some ctx DT_TABLE
# ovar: original name of some variable "var" without prefix
var() {
  local var val table record var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift; val="$*"
  table=$(get_table) && \
  record=$(get_record) && \
  err_if_empty ${fname} "var" && \
  fq_var=$(var_fqn ${table} ${record} ${var}) || return $?
  local msg_tmpl="${BOLD}${fq_var}${RESET} to value '${BOLD}${val}${RESET}'"
  if declare -p ${fq_var} >/dev/null 2>&1; then
    dt_warning ${fname} "Resetting ${msg_tmpl}"
  else
    dt_debug ${fname} "Setting ${msg_tmpl}"
    DT_VARS+=("${fq_var}")
    eval "${var}() { get_var ${var} \$1 \$2 \$3 \$4; }"
  fi
  eval "${fq_var}=\"${val}\""
}

# merges var in parent ctx DT_PARENT and with one in ctx DT_TABLE
# ovar: original name of some variable "var" without prefix
mvar() {
  local var val pval table record var=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  shift; val="$*"
  table=$(get_table) && \
  record=$(get_record) && \
  err_if_empty ${fname} "var" && \
  fq_var=$(var_fqn ${table} ${record} ${var}) || return $?
  dt_debug ${fname} "fq_var=${BOLD}${fq_var}${RESET}"
  if declare -p ${fq_var} >/dev/null 2>&1; then
    val="$(eval echo \$${fq_var})" || return $?
    dt_debug ${fname} "Skip merge for var ${BOLD}${fq_var}${RESET}: it has already set and its value is '${BOLD}${val}${RESET}'"
    return 0
  fi
  dt_debug ${fname} "Merging var ${BOLD}${fq_var}${RESET} with parent ctx '${BOLD}${DT_PARENT}${RESET}'"
  if [ -z "${DT_PARENT}" ]; then
    pval="$*"
    var "${var}" "${pval}" || return $?
  else
    pval=$(${var} -t "${table}" -r "${DT_PARENT}")
    var "${var}" "${pval}" || return $?
  fi
}

table() {
  local mergefunc table tbl=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  table=$(tbl_name "${tbl}") && \
  if [ "$2" = "-m" ]; then
    if [ -z $3 ]; then dt_error ${fname} "Merge function was not provided"; return 99; fi
    mergefunc="merge_$3"
    if ! declare -f "${mergefunc}" >/dev/null 2>&1; then
      dt_error ${fname} "Provided merge function ${BOLD}${mergefunc}${RESET} doesn't exist"
      return 99
    fi
  else
    dt_error ${fname} "Merge function was not provided"
    return 99
  fi && \
  if ! declare -p "${table}" >/dev/null 2>&1; then
    eval "${table}="
    eval "${table}_merge=${mergefunc}"
    DT_VARS+=("${table}") && \
    DT_VARS+=("${table}_merge") || return $?
  fi && \
  set_tbl "${table}"
}

record() {
  local mergefunc table record parent fq_rec rec="$1" fname=$(fname "${FUNCNAME[0]}" "$0")
  table=$(get_table) && \
  record=$(rec_name "${rec}") && \
  fq_rec=$(rec_fqn "${table}" "${record}") && \
  if declare -p "${record}" >/dev/null 2>&1; then
    dt_error ${fname} "Record ${BOLD}${fq_rec}${RESET} already exists"
    return 99
  fi && \
  if [ "$2" = "-m" ]; then
    if [ -z $3 ]; then dt_error ${fname} "Merge function was not provided"; return 99; fi
    mergefunc="merge_$3"
    if ! declare -f "${mergefunc}" >/dev/null 2>&1; then dt_error ${fname} "Provided merge function ${BOLD}${mergefunc}${RESET} doesn't exist"; return 99; fi
  elif [ "$2" = "-p" ]; then
    if [ -z $3 ]; then dt_error ${fname} "Parent was not provided"; return 99; fi
    parent=$(rec_name "$3")
    if ! declare -p "${parent}" >/dev/null 2>&1; then dt_error ${fname} "Provided parent record ${BOLD}${parent}${RESET} doesn't exist"; return 99; fi
  else
    parent=$(rec_name "$(echo "${rec}" | awk -F':' 'OFS=":" {NF=NF-1; print $0}')")
  fi && \
  dt_debug ${fname} "rec=${rec}, parent=${parent}, mergefunc=${mergefunc}" && \
  if [ -z "${mergefunc}" ]; then mergefunc="$(eval echo "\$${table}_merge")"; fi && \
  if [ -z "${parent}" ] && [ -z "${mergefunc}" ]; then
    dt_error ${fname} "Nor merge function neither parent was provided"
    return 99
  fi && \
  if [ -n "${parent}" ]; then
    parent="$(get_record "${parent}")" || return $?
  fi && \
  DT_VARS+=("${fq_rec}") && \
  DT_VARS+=("${fq_rec}_merge") && \
  DT_VARS+=("${fq_rec}_parent") || return $?
  eval "${fq_rec}="
  eval "${fq_rec}_parent=${parent}"
  eval "${fq_rec}_merge=${mergefunc}"
  set_rec "${record}"
}

get_merge() {
  local ctx=$1 pctx="$2" fname=$(fname "${FUNCNAME[0]}" "$0")
  if declare -p "${ctx}_merge" >/dev/null 2>&1; then
    echo "$(eval echo "\$${record}_merge")"
  elif declare -p "${pctx}_merge" >/dev/null 2>&1; then
    echo "$(eval echo "\$${pctx}_merge")"
  else
    dt_error ${fname} "Cannot find merge function"
  fi
}

merge() {
  local DT_PARENT mergefunc table record parent fq_rec fname=$(fname "${FUNCNAME[0]}" "$0")
  table=$(get_table) && \
  record="$(get_record "${DT_RECORD}")" && \
  fq_rec=$(rec_fqn "${table}" "${record}") && \
  if declare -p "${fq_rec}_merged" >/dev/null 2>&1; then
    dt_error ${fname} "Record ${BOLD}${fq_rec}${RESET} has already merged"
    return 99
  fi
  DT_PARENT="$(eval echo "\$${fq_rec}_parent")"
  mergefunc="$(eval echo "\$${fq_rec}_merge")"
  if [ -z "${DT_PARENT}" ] && [ -z "${mergefunc}" ]; then
    dt_error ${fname} "Nor merge function neither parent was provided"
    return 99
  fi && \
  dt_debug ${fname} "Merge function is ${BOLD}${mergefunc}${RESET}, parent=${DT_PARENT}"
  ${mergefunc}
  eval "${fq_rec}_merged=yes"
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
