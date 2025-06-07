clickhouse_version=(MAJOR MINOR PATCH)
clickhouse_socket=(CLICKHOUSE_HOST CLICKHOUSE_PORT)
clickhouse_paths=(CH_USER_XML_DIR CH_USER_XML CH_CONFIG_XML)
clickhouse_vars=(${clickhouse_version[@]} ${clickhouse_socket[@]} ${clickhouse_paths[@]} ${service[@]} ${dt_vars[@]})

function clickhouse_conf() {
  if [ "$(os_name)" = "macos" ]; then
    CH_CONFIG_XML="$(brew_prefix)/etc/clickhouse-server/config.xml"
  else
    CH_CONFIG_XML="/etc/clickhouse-server/config.xml"
  fi
}

function clickhouse_user_xml_dir() {
  if [ "$(os_name)" = "macos" ]; then
    CH_USER_XML_DIR="$(brew_prefix)/etc/clickhouse-server/users.d"
  else
    CH_USER_XML_DIR="/etc/clickhouse-server/users.d"
  fi
}

# ctx_service_clickhouse && clickhouse_install
function clickhouse_install() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    dt_exec "${SUDO} apt-get install -y apt-transport-https ca-certificates curl gnupg" || return $?
    dt_exec "curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | ${SUDO} gpg --batch --yes --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg" || return $?
    dt_exec "echo 'deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main' | ${SUDO} tee /etc/apt/sources.list.d/clickhouse.list" || return $?
    dt_exec "${SUDO} apt-get update" || return $?
    dt_exec "${SUDO} apt-get install -y clickhouse-server clickhouse-client" || return $?
  elif [ "$(os_kernel)" = "Darwin" ]; then
    dt_exec "brew install '${SERVICE}'" || return $?
  else
    dt_error ${fname}  "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function clickhouse_user_xml() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_load_vars -c ctx_clickhouse_admin || return $?
  dt_err_if_empty ${fname} "CLICKHOUSE_USER" || return $?
  dt_err_if_empty ${fname} "CLICKHOUSE_PASSWORD" || return $?
  query=$(
    dt_escape_quote "<?xml version=\"1.0\"?>
<yandex>
    <profiles>
        <default>
            <union_default_mode>ALL</union_default_mode>
        </default>
    </profiles>
    <users>
        <default>
            <access_management>1</access_management>
        </default>
        <${CLICKHOUSE_USER}>
            <password>${CLICKHOUSE_PASSWORD}</password>
            <access_management>1</access_management>
        </${CLICKHOUSE_USER}>
    </users>
</yandex>"
)
  echo -n "${query}"
}

function clickhouse_gen_user_xml() {
  local fname old_hash new_hash cmd query SUDO
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" != "macos" ]; then
    SUDO="sudo"
  fi
  if [ -f "${CH_USER_XML}" ]; then
    old_hash=$(dt_exec "${SUDO} sha256sum "${CH_USER_XML}" | cut -d' ' -f 1") || return $?
  fi
  dt_debug ${fname} "old_hash=${BOLD}${old_hash}${RESET}"
  query="$(clickhouse_user_xml)" || return $?
  cmd="echo $'${query}' | tee ${CH_USER_XML}"
  dt_exec "${cmd}" || return $?
  new_hash=$(dt_exec "${SUDO} sha256sum "${CH_USER_XML}" | cut -d' ' -f 1") || return $?
  dt_debug ${fname} "new_hash=${new_hash}"
  if [ "${old_hash}" != "${new_hash}" ]; then dt_debug ${fname} "${POSTGRESQL_CONF} is changed"; return 77; fi
}

function clickhouse_prepare() {
  local changed
  changed=$(clickhouse_gen_user_xml); err=$?
  if [ "${err}" != 77 ]; then return ${err}; fi
  service_stop
}

function clickhouse_paths() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  clickhouse_user_xml_dir && clickhouse_conf || return $?
  CH_USER_XML="${CH_USER_XML_DIR}/dt_admin.xml"
  CH_CONFIG_XML=${CH_CONFIG_XML}
}

function clickhouse_service() {
  if [ "$(os_name)" = "macos" ]; then
    SERVICE="clickhouse@${MAJOR}.${MINOR}"
  else
    SERVICE="clickhouse-server"
  fi
  clickhouse_paths || return $?
  STOP="$(service) stop '${SERVICE}'"
  START="$(service) start '${SERVICE}'"
  PREPARE=clickhouse_prepare
  INSTALL=clickhouse_install
  LSOF=lsof_clickhouse
}

function ctx_service_clickhouse() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=("${clickhouse_vars}")
  CLICKHOUSE_HOST="localhost"
  # for clickhouse-client
  CLICKHOUSE_PORT=9000
  # for applications
  CLICKHOUSE_HTTP_PORT=8123
  MAJOR=23
  MINOR=5
  clickhouse_service
  dt_set_ctx -c ${ctx}
}

function lsof_clickhouse() {
  HOST=${CLICKHOUSE_HOST}
  PORT=${CLICKHOUSE_PORT}
  lsof_tcp
  PORT=${CLICKHOUSE_HTTP_PORT};
  lsof_tcp
}

dt_register "ctx_service_clickhouse" "clickhouse" "${service_methods[@]}"

#function service_prepare_clickhouse() {
#  ctx_conn_clickhouse_admin && clickhouse_prepare $1
#}
