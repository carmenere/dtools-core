# Conventions
#   DT_AUTOCOMPLETE - record names, will be used as variants for autocomplete
#   autocomplete_%TBL% - custom autocomplete function
#   methods_%TBL% - methods to be bound to autocomplete_%TBL%

declare -A DT_AUTOCOMPLETE
DT_TABLES=(conns)

select_autocomplete_variants() {
  local autocomplete_id tbl=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  local VARIANTS=()
  IFS_ORIGIN="${IFS}"
  if [ -z "${tbl}" ]; then dt_error ${fname} "Table name is mandatory, but it was not provided"; fi
  while read row; do
      VARIANTS+=("${row}")
  done < <(
sqlite3 -batch -noheader "${DT_VARS_DB}" -cmd 'PRAGMA foreign_keys = ON;' <<EOF
    select DISTINCT autocomplete_id FROM ${tbl};
EOF
)
  IFS="${IFS_ORIGIN}"
  DT_AUTOCOMPLETE["${tbl}"]="${VARIANTS[@]}"
  echo "variants: ${DT_AUTOCOMPLETE["${tbl}"]}"
}
select_autocomplete_variants conns

dt_gen_autocomplete() {
  local func tbl=$1
  select_autocomplete_variants $1 || return $?
  func="autocomplete_${tbl}() {
  local cur_word="\${COMP_WORDS\[COMP_CWORD\]}"
  local options=\"\${DT_AUTOCOMPLETE[\"${tbl}\"]}\"
  COMPREPLY=( \$(compgen -W \"\${options}\" -- \"\${cur_word}\") ) }"
  eval "$(echo -e "${func}")"
}

dt_tbl_autocomplete() {
  local tbl methods autocomplete fname=$(fname "${FUNCNAME[0]}" "$0")
  tbl="$1" && \
  methods="methods_${tbl}" && \
  if ! declare -f "${methods}" >/dev/null 2>&1; then return 0; fi && \
  autocomplete="autocomplete_${tbl}" && \
  dt_debug ${fname} "dt_gen_autocomplete ${tbl}" && \
  dt_gen_autocomplete "${tbl}" && \
  dt_debug ${fname} "done" && \
  methods=($(echo "$(${methods})")) && \
  for m in ${methods[@]}; do
    dt_debug ${fname} "complete -F ${autocomplete} ${m}"
    complete -F "${autocomplete}" "${m}"
  done
}

dt_autocomplete() {
  local tables tbl fname=$(fname "${FUNCNAME[0]}" "$0")
  for tbl in ${DT_TABLES[@]}; do
    dt_debug ${fname} "dt_tbl_autocomplete ${tbl}"
    dt_tbl_autocomplete "${tbl}"
  done
}