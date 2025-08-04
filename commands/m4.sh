_m4() {
  exec_cmd "m4 ${M4_TVARS} ${M4_IN} > ${M4_OUT}"
}

m4_query() {
  local M4_OUT=${DT_M4_OUT}/sql/${SERVICE_ID}/$1
  mkdir -p "$(dirname "${DT_M4_OUT}")"
  M4_TVARS=${DT_M4}/m4/$2
  M4_IN=${DT_M4}/m4/$1
  _m4
  if [ -z "$(tail -c 1 ${OUT})" ]; then echo "" >> ${OUT}; fi
}

##################################################### AUTOCOMPLETE #####################################################
function methods_m4() {
  local methods=()
  methods+=("$(methods_m4_pg)")
  echo "${methods[@]}"
}

DT_AUTOCOMPLETE+=(methods_m4)
DT_AUTOCOMPLETIONS["methods_m4"]=""