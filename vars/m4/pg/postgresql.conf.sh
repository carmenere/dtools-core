. <(. ${DT_VARS}/services/pg.sh && echo "export M4_PORT=${PORT_BIND}" && echo "M4_OUT=$(postgresql_conf)")
echo "M4_PORT=${M4_PORT}"
export M4_PORT
M4_IN="${DTOOLS}/core/m4/pg/postgresql.conf"
M4_TVARS="${M4_IN}.m4"
