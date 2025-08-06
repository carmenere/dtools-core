ch_install() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    exec_cmd "${SUDO} apt-get install -y apt-transport-https ca-certificates curl gnupg" || return $?
    exec_cmd "curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | ${SUDO} gpg --batch --yes --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg" || return $?
    exec_cmd "echo 'deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main' | ${SUDO} tee /etc/apt/sources.list.d/clickhouse.list" || return $?
    exec_cmd "${SUDO} apt-get update" || return $?
    exec_cmd "${SUDO} apt-get install -y clickhouse-server clickhouse-client" || return $?

  elif [ "$(os_kernel)" = "Darwin" ]; then
    exec_cmd "brew install '$(clickhouse_service)'"

  else
    echo "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

ch_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "clickhouse@${MAJOR}.${MINOR}"
  else
    echo "clickhouse-server"
  fi
}

ch_config.xml() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/etc/clickhouse-server/config.xml"
  else
    echo "/etc/clickhouse-server/config.xml"
  fi
}

ch_user.xml() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/etc/clickhouse-server/users.d/dt_user.xml"
  else
    echo "/etc/clickhouse-server/users.d/dt_user.xml"
  fi
}

m4_clickhouse_user.xml() {( set -eu; . "${DT_VARS}/m4/$1/user.xml.sh" && _m4 )}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_m4_clickhouse() {
  local methods=()
  methods+=(m4_clickhouse_user.xml)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_m4_clickhouse"
