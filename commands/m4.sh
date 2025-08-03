_m4() {
  exec_cmd "m4 ${M4_TVARS} ${M4_IN} > ${M4_OUT}"
}

#m4_drop_user() {
#  OUT="/tmp/templates/m4/pg/sql/drop_user.sql" && \
#  exec_cmd "m4 ${DTOOLS}/core/templates/m4/pg/sql/vars.m4 ${DTOOLS}/core/templates/m4/pg/sql/drop_user.sql > ${OUT}" && \
#  if [ -z "$(tail -c 1 ${OUT})" ]; then echo "" >> ${OUT}; fi && \
#  exec_cmd "cat ${OUT}" && \
#  exec_cmd PGPORT=1111 PGDATABASE=postgres psql -f ${OUT}
#}

##################################################### AUTOCOMPLETE #####################################################
function methods_m4() {
  local methods=()
  methods+=(m4_postgresql.conf)
  echo "${methods[@]}"
}

DT_AUTOCOMPLETE+=(methods_m4)
DT_AUTOCOMPLETIONS["methods_m4"]="postgresql.conf"