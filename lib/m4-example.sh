#OUT="/tmp/templates/m4/pg/sql/drop_user.sql" && \
#exec_cmd "m4 ${DTOOLS}/core/templates/m4/pg/sql/vars.m4 ${DTOOLS}/core/templates/m4/pg/sql/drop_user.sql > ${OUT}" && \
#if [ -z "$(tail -c 1 ${OUT})" ]; then echo "" >> ${OUT}; fi && \
#exec_cmd "cat ${OUT}" && \
#exec_cmd PGPORT=1111 PGDATABASE=postgres psql -f ${OUT}