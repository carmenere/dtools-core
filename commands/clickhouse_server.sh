ch_install() {(
  local fname=ch_install
  set -eu; . "${DT_VARS}/services/$1.sh"
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    exec_cmd "${SUDO} apt-get install -y apt-transport-https ca-certificates curl gnupg" || return $?
    exec_cmd "curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | ${SUDO} gpg --batch --yes --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg" || return $?
    exec_cmd "echo 'deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main' | ${SUDO} tee /etc/apt/sources.list.d/clickhouse.list" || return $?
    exec_cmd "${SUDO} apt-get update" || return $?
    exec_cmd "${SUDO} apt-get install -y clickhouse-server clickhouse-client" || return $?

  elif [ "$(os_kernel)" = "Darwin" ]; then
    exec_cmd "brew install '${OS_SERVICE}'"

  else
    echo "Unsupported OS: '$(os_kernel)'"; return 99
  fi
)}

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

ch_prepare() {(
  local fname=ch_prepare
  set -eu
  local FILE hash_old hash_new
  local changed=0
  . "${DT_VARS}/services/$1.sh"
  if [ "${MODE}" != "host" ]; then
    dt_info ${fname} "Service ${BOLD}$1${RESET}: MODE != host, skip prepare"
    return 0
  fi

  FILE=$(ch_user.xml)
  hash_old=$(${SUDO} sha256sum "${FILE}" | cut -d' ' -f 1)
  m4_clickhouse_user.xml $1
  hash_new=$(${SUDO} sha256sum "${FILE}" | cut -d' ' -f 1)
  if [ "${hash_old}" != "${hash_new}" ]; then
    changed=1
    dt_info ${fname} "File ${FILE} was ${BOLD}changed${RESET}, service will be stopped"
  fi

  if [ "${changed}" != 0 ]; then service_stop $1; fi
)}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_clickhouse_services() {
  local methods=()
  methods+=(ch_install)
  methods+=(m4_clickhouse_user.xml)
  methods+=(ch_prepare)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_clickhouse_services"
