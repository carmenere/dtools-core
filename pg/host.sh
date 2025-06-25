# PG_MODE={ host | docker }, by default "host"
# Exported to be seen in child process, if set in parent - do not change.
if [ -z "${PG_MODE}" ]; then export PG_MODE="host"; fi

pg_mode() {
  if [ "${PG_MODE}" = "docker" ]; then
    echo "docker"
  elif [ "${PG_MODE}" = "host" ]; then
    echo "host"
  else
    dt_error ${fname} "Unknown pg mode: PG_MODE=${PG_MODE}"
    return 99
  fi
}

set_pg_mode_docker() {
  PG_MODE=docker
  reinit_dtools && \
  dt_info pg_set_mode_docker "PG_MODE=${PG_MODE}"
}

set_pg_mode_host() {
  PG_MODE=host
  reinit_dtools && \
  dt_info pg_set_mode_host "PG_MODE=${PG_MODE}"
}

function pg_superuser() {
  if [ "$(os_name)" = "macos" ] && [ "$(pg_mode)" = "host" ]; then
    echo "${USER}"
  else
    echo "postgres"
  fi
}

# ctx_pg_host && pg_install
function pg_install() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    exec_cmd "echo 'deb http://apt.postgresql.org/pub/repos/apt $(os_codename)-pgdg main' | ${SUDO} tee /etc/apt/sources.list.d/pgdg.list" || return $?
    exec_cmd "${SUDO} wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | ${SUDO} apt-key add -" || return $?
    exec_cmd "${SUDO} apt-get update" || return $?
    exec_cmd "${SUDO} apt-get -y install \
      postgresql-$(MAJOR) \
      postgresql-server-dev-$(MAJOR) \
      libpq-dev" || return $?
  elif [ "$(os_kernel)" = "Darwin" ]; then
    exec_cmd "brew install $(SERVICE)"
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function bin_dir() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "macos" ]; then
    bind_dir="$(brew_prefix)/opt/postgresql@$(MAJOR)/bin"
  elif [ "$(os_name)" = "alpine" ]; then
    bind_dir="/usr/libexec/postgresql$(MAJOR)"
  else
    bind_dir="/usr/lib/postgresql/$(MAJOR)/bin"
  fi
  if [ ! -d "${bind_dir}" ]; then
    dt_warning ${fname} "The directory '${bind_dir}' doesn't exist"
  fi
  echo "${bind_dir}"
}

function pg_hba_conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/$(SERVICE)/pg_hba.conf"
  else
    echo "/etc/postgresql/$(MAJOR)/main/pg_hba.conf"
  fi
}

function postgresql_conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/$(SERVICE)/postgresql.conf"
  else
    echo "/etc/postgresql/$(MAJOR)/main/postgresql.conf"
  fi
}

function pg_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "postgresql@$(MAJOR)"
  else
    echo "postgresql"
  fi
}

function pg_add_path() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  path="${PATH}"
  echo "${path}" | grep -E -s "^$(bin_dir)" 1>/dev/null 2>&1
  if [ $? != 0 ] && [ -n "$(bin_dir)" ]; then
    # Cut all duplicates of $(bin_dir) from path
    path="$(echo "${path}" | sed -E -e ":label; s|(.*):$(bin_dir)(.*)|\1\2|g; t label;")"
    # Prepend $(bin_dir)
    dt_debug ${fname} "$(bin_dir):${path}"
  else
    dt_debug ${fname} "${path}"
  fi
}

function pg_hba_add_policy() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  old_hash=$(${SUDO} sha256sum "$(PG_HBA_CONF)" | cut -d' ' -f 1) && \
  exec_cmd "${SUDO} sed -i -E -e 's/^\s*#?\s*host\s+all\s+all\s+0.0.0.0\/0\s+md5\s*$/host all all 0.0.0.0\/0 md5/; t; \$a host all all 0.0.0.0\/0 md5' $(PG_HBA_CONF)" && \
  new_hash=$(${SUDO} sha256sum "$(PG_HBA_CONF)" | cut -d' ' -f 1) && \
  if [ "${old_hash}" != "${new_hash}" ]; then
    dt_info ${fname} "$(PG_HBA_CONF) is ${BOLD}is changed${RESET}"; return 77
  else
    dt_info ${fname} "$(PG_HBA_CONF) is ${BOLD}not changed${RESET}"
  fi
}

function pg_conf_set_port() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  old_hash=$(${SUDO} sha256sum "$(POSTGRESQL_CONF)" | cut -d' ' -f 1) && \
  exec_cmd "${SUDO} sed -i -E -e 's/^\s*#?\s*(port\s*=\s*[0-9]+)\s*$/port = $(PGPORT)/; t; \$a port = $(PGPORT)' $(POSTGRESQL_CONF)" && \
  new_hash=$(${SUDO} sha256sum "$(POSTGRESQL_CONF)" | cut -d' ' -f 1) && \
  if [ "${old_hash}" != "${new_hash}" ]; then
    dt_info ${fname} "$(POSTGRESQL_CONF) is ${BOLD}is changed${RESET}"; return 77
  else
    dt_info ${fname} "$(POSTGRESQL_CONF) is ${BOLD}not changed${RESET}"
  fi
}

# OS service methods
function pg_prepare() {
  local changed
  pg_hba_add_policy; err=$?; if [ "${err}" = 77 ]; then changed="y"; elif [ "${err}" != "0" ]; then return ${err}; fi && \
  pg_conf_set_port;  err=$?; if [ "${err}" = 77 ]; then changed="y"; elif [ "${err}" != "0" ]; then return ${err}; fi && \
  if [ "${changed}" != "y" ]; then return 0; fi && \
  service_stop_pg
}

function lsof_pg() {
  PORT=$(PGPORT); HOST=$(PGHOST)
  lsof_tcp
}

function ctx_pg_host() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var MAJOR 17 && \
  var MINOR 5 && \
  var PGHOST "localhost" && \
  var PGPORT 5555 && \
  var SERVICE $(pg_service) && \
  var BIN_DIR $(bin_dir) && \
  var PG_HBA_CONF $(pg_hba_conf) && \
  var POSTGRESQL_CONF $(postgresql_conf) && \
  var PSQL "$(BIN_DIR)/psql" && \
  var PG_CONFIG "$(BIN_DIR)/pg_config" && \
  if [ ! -x "$(PG_CONFIG)" ]; then
    dt_warning ${fname} "The binary '$(PG_CONFIG)' doesn't exist" || return $?
  else
    var CONFIG_SHAREDIR "$($(PG_CONFIG) --sharedir)"  && \
    var CONFIG_LIBDIR "$($(PG_CONFIG) --pkglibdir)" || return $?
  fi
  var SERVICE_CHECK_CMD "psql_local_conn_admin -c \$\'select true;\'" && \
  var SERVICE_PREPARE "pg_prepare" && \
  var SERVICE_INSTALL "pg_install" && \
  var SERVICE_LSOF "lsof_pg" && \
  ctx_os_service ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_pg_host:pg:service_methods)
