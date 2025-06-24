# PROFILE_CLICKHOUSE={ host | docker }, by default "host"
if [ -z "${PROFILE_CLICKHOUSE}" ]; then export PROFILE_CLICKHOUSE="host"; fi

clickhouse_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "clickhouse@$(MAJOR).$(MINOR)"
  else
    echo "clickhouse-server"
  fi
}

clickhouse_conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/etc/clickhouse-server/config.xml"
  else
    echo "/etc/clickhouse-server/config.xml"
  fi
}

# ctx_host_clickhouse && clickhouse_install
clickhouse_install() {
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

clickhouse_user_xml() {
  local query=$(
    escape_quote "<?xml version=\"1.0\"?>
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
        <$(CLICKHOUSE_USER)>
            <password>$(CLICKHOUSE_PASSWORD)</password>
            <access_management>1</access_management>
        </$(CLICKHOUSE_USER)>
    </users>
</yandex>"
)
  echo -n "${query}"
}

clickhouse_gen_user_xml() {
  if [ "$(os_name)" = "macos" ]; then
    # sudo -E: indicates to the security policy that the user wishes to preserve their existing environment variables.
    # The security policy may return an error if the user does not have permission to preserve the environment.
    local SUDO="sudo -E"
  else
    local SUDO="sudo"
  fi
  local query="$(clickhouse_user_xml)"
  local cmd="echo $'${query}' | sudo tee $(CH_USER_XML)"
  exec_cmd "${cmd}"
}

clickhouse_prepare() {
  if [ -f "$(CH_USER_XML)" ]; then
    local user_xml_hash=$(${SUDO} sha256sum "$(CH_USER_XML)" | cut -d' ' -f 1)
  fi
  clickhouse_gen_user_xml
  local user_xml_hash_new=$(${SUDO} sha256sum "$(CH_USER_XML)" | cut -d' ' -f 1)
  if [ "${user_xml_hash}" = "${user_xml_hash_new}" ]; then return 0; fi
  service_stop
}

clickhouse_user_xml_dir() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/etc/clickhouse-server/users.d"
  else
    echo "/etc/clickhouse-server/users.d"
  fi
}

service_prepare_clickhouse() { ctx_conn_clickhouse && ctx_conn_clickhouse_admin && clickhouse_prepare $1; }

lsof_clickhouse() {
  HOST=$(CLICKHOUSE_HOST)
  PORT=$(CLICKHOUSE_PORT)
  lsof_tcp
  PORT=$(CLICKHOUSE_HTTP_PORT);
  lsof_tcp
}

ctx_host_clickhouse() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var CLICKHOUSE_HOST "localhost" && \
  # for clickhouse-client
  var CLICKHOUSE_PORT 9000 && \
  # for applications
  var CLICKHOUSE_HTTP_PORT 8123 && \
  var MAJOR 23 && \
  var MINOR 5 && \
  var CH_USER_XML "$(clickhouse_user_xml_dir)/admin.xml" || return $? && \
  var CH_CONFIG_XML $(clickhouse_conf) || return $? && \
  var SERVICE $(clickhouse_service) && \
  var SERVICE_CHECK_CMD "clickhouse_conn_admin --query \"'exit'\"" && \
  var SERVICE_PREPARE clickhouse_prepare && \
  var SERVICE_INSTALL clickhouse_install && \
  var SERVICE_LSOF lsof_clickhouse && \
  ctx_os_service ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_host_clickhouse:clickhouse:service_methods)
