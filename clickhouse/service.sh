function clickhouse_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "clickhouse@${MAJOR}.${MINOR}"
  else
    echo "clickhouse-server"
  fi
}

function clickhouse_conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/etc/clickhouse-server/config.xml"
  else
    echo "/etc/clickhouse-server/config.xml"
  fi
}

# ctx_service_clickhouse && clickhouse_install
function clickhouse_install() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    dt_exec "${SUDO} apt-get install -y apt-transport-https ca-certificates curl gnupg"; exit_on_err ${fname} $? || return $?
    dt_exec "curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | ${SUDO} gpg --batch --yes --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg"; exit_on_err ${fname} $? || return $?
    dt_exec "echo 'deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main' | ${SUDO} tee /etc/apt/sources.list.d/clickhouse.list"; exit_on_err ${fname} $? || return $?
    dt_exec "${SUDO} apt-get update"; exit_on_err ${fname} $? || return $?
    dt_exec "${SUDO} apt-get install -y clickhouse-server clickhouse-client"; exit_on_err ${fname} $? || return $?

  elif [ "$(os_kernel)" = "Darwin" ]; then
    dt_exec "brew install '$(clickhouse_service)'"

  else
    echo "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function clickhouse_user_xml() {
  local query=$(
    dt_escape_single_quotes "<?xml version=\"1.0\"?>
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
  if [ "$(os_name)" = "macos" ]; then
    # sudo -E: indicates to the security policy that the user wishes to preserve their existing environment variables.
    # The security policy may return an error if the user does not have permission to preserve the environment.
    local SUDO="sudo -E"
  else
    local SUDO="sudo"
  fi
  local query="$(clickhouse_user_xml)"
  local cmd="echo $'${query}' | sudo tee ${CH_USER_XML}"
  dt_exec "${cmd}"
}

function clickhouse_prepare() {
  if [ -f "${CH_USER_XML}" ]; then
    local user_xml_hash=$(${SUDO} sha256sum "${CH_USER_XML}" | cut -d' ' -f 1)
  fi
  clickhouse_gen_user_xml
  local user_xml_hash_new=$(${SUDO} sha256sum "${CH_USER_XML}" | cut -d' ' -f 1)
  if [ "${user_xml_hash}" = "${user_xml_hash_new}" ]; then return 0; fi
  service_stop
}

function clickhouse_user_xml_dir() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/etc/clickhouse-server/users.d"
  else
    echo "/etc/clickhouse-server/users.d"
  fi
}

function ctx_clickhouse_vars() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  CH_USER_XML="$(clickhouse_user_xml_dir)/dt_admin.xml"; exit_on_err ${fname} $? || return $?
  CH_CONFIG_XML=$(clickhouse_conf); exit_on_err ${fname} $? || return $?
  SERVICE_STOP="$(service) stop '$(clickhouse_service)'"
  SERVICE_START="$(service) start '$(clickhouse_service)'"
  SERVICE_PREPARE=clickhouse_prepare
  SERVICE_INSTALL=clickhouse_install
  SERVICE_LSOF=lsof_clickhouse
}

function ctx_service_clickhouse() {
  CLICKHOUSE_HOST="localhost"
  # for clickhouse-client
  CLICKHOUSE_PORT=9000
  # for applications
  CLICKHOUSE_HTTP_PORT=8123
  MAJOR=23
  MINOR=5
  ctx_clickhouse_vars
}

function lsof_clickhouse() {
  HOST=${CLICKHOUSE_HOST}
  PORT=${CLICKHOUSE_PORT}
  lsof_tcp
  PORT=${CLICKHOUSE_HTTP_PORT};
  lsof_tcp
}

dt_register "ctx_service_clickhouse" "clickhouse" "${service_methods[@]}"

function service_prepare_clickhouse() {
  ctx_conn_clickhouse_admin && clickhouse_prepare $1
}
