. <(
  . ${DT_VARS}/services/clickhouse.sh
  echo "M4_OUT=$(ch_user.xml)"
)

. <(
  . ${DT_VARS}/conns/accounts/clickhouse/admin.sh
  echo "M4_OUT=$(ch_user.xml)"
  echo "M4_PASSWORD=${password}"
  echo "M4_USER=${user}"
)

declare -A envs
ENVS=()
add_env M4_PASSWORD ${M4_PASSWORD}
add_env M4_USER ${M4_USER}

M4_IN="${DT_M4}/clickhouse/user.xml"
M4_TVARS="${M4_IN}.m4"
