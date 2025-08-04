. <(
  . ${DT_VARS}/services/pg.sh
  echo "M4_OUT=$(pg_pg_hba.conf)"
)
export M4_HBA_POLICY='host all all 0.0.0.0/0 md5'
echo M4_HBA_POLICY=${M4_HBA_POLICY}
M4_IN="${DT_M4}/pg/pg_hba.conf"
M4_TVARS="${M4_IN}.m4"
