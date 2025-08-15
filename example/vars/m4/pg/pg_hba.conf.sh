. <(
  . ${DT_VARS}/services/pg_17.sh
  echo "M4_OUT=$(pg_pg_hba.conf)"
)
declare -A envs
ENVS=()
add_env M4_HBA_POLICY 'host all all 0.0.0.0/0 md5'
M4_IN="${DT_M4}/pg/pg_hba.conf"
M4_TVARS="${M4_IN}.m4"
