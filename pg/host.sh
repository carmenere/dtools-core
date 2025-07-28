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

set_mode_pg_docker() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  PG_MODE=docker
  if is_var_changed PG_MODE; then drop_vars; fi && \
  dt_info ${fname} "PG_MODE=${PG_MODE}"
}

set_mode_pg_host() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  PG_MODE=host
  if is_var_changed PG_MODE; then drop_vars; fi && \
  dt_info ${fname} "PG_MODE=${PG_MODE}"
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
    exec_cmd "echo 'deb http://apt.postgresql.org/pub/repos/apt $(os_codename)-pgdg main' | ${SUDO} tee /etc/apt/sources.list.d/pgdg.list" && \
    exec_cmd "${SUDO} wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | ${SUDO} apt-key add -" && \
    exec_cmd "${SUDO} apt-get update" && \
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

# Drop pg cluster: sudo pg_dropcluster N main
pg_post_install() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    if ! pg_lsclusters | cut -d' ' -f 1 | grep -m 1 "$(MAJOR)"; then
      exec_cmd ${SUDO} pg_createcluster $(MAJOR) main && \
      exec_cmd ${SUDO} pg_ctlcluster $(MAJOR) main start
    fi && \
    ${self}__service_prepare && \
    ${self}__service_start
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
    echo "postgresql@$(MAJOR)-main.service"
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
  DEFAULT_POLICY="host all all 0.0.0.0/0 md5"
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
  local port=$(PORT $(SOCK)) && \
  old_hash=$(${SUDO} sha256sum "$(POSTGRESQL_CONF)" | cut -d' ' -f 1) && \
  exec_cmd "${SUDO} sed -i -E -e 's/^\s*#?\s*(port\s*=\s*[0-9]+)\s*$/port = ${port}/; t; \$a port = ${port}' $(POSTGRESQL_CONF)" && \
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
  service_stop ${DT_RECORD}
}
