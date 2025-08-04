. <(
  . ${DT_VARS}/services/pg.sh
  echo "export M4_PORT=\"${PORT_BIND}\""
  echo "M4_OUT=$(pg_postgresql.conf)"
)
M4_IN="${DT_M4}/pg/postgresql.conf"
M4_TVARS="${M4_IN}.m4"
