# Conventions
#   autocomplete_%TBL% - custom autocomplete function
#   records_%TBL% - record names, will be used as words for autocomplete
#   methods_%TBL% - methods to be bound to autocomplete_%TBL%

dt_gen_autocomplete() {
  local func tbl=$1
  func="autocomplete_${tbl}() {
  local cur_word="\${COMP_WORDS\[COMP_CWORD\]}"
  local options=\"\${records_${tbl}[@]}\"
  COMPREPLY=( \$(compgen -W \"\${options}\" -- \"\${cur_word}\") ) }"
  eval "$(echo -e "${func}")"
}

dt_tbl_autocomplete() {
  local methods autocomplete fname=$(fname "${FUNCNAME[0]}" "$0")
  tbl=$(get_table $1) && \
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