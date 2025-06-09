#if [ -n "${BASH_SOURCE}" ]; then CTX="${BASH_SOURCE[0]}"; else CTX="$0"; fi
##eval "${ctx}=$(echo ${CTX} | tr './' '_')"

#function major() { echo 17; }
#function minor() { echo 5; }
#function host() { echo "localhost"; }
#function port() { echo 5430; }
#function psql() { echo "$(bin_dir)/psql"; }
#function pg_config() { echo "$(bin_dir)/pg_config"; }
#function config_sharedir() { echo "$("$(pg_config)" --sharedir)"; }
#function pg_paths() { local fname=$(dt_fname "${FUNCNAME[0]}" "$0"); }
#function config_libdir() { echo "$("$(pg_config)" --pkglibdir | tr ' ' '\n')"; }

function PG_CONFIG() {
  local fname ctx pg_config major
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  shift
  pg_config=$(gvar ${ctx} PG_CONFIG)
  major=$(gvar ${ctx} MAJOR)
  if [ ! -x "${pg_config}" ]; then
    dt_warning ${fname} "The binary '${pg_config}' doesn't exist. Maybe pg of version '${major}' hasn't been installed yet?"
    return 0
  fi
  echo "${pg_config} $@"
}

function bin_dir() {
  local fname ctx major bind_dir
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  major=$(gvar ${ctx} MAJOR)
  if [ "$(os_name)" = "macos" ]; then
    bind_dir="$(brew_prefix)/opt/postgresql@${major}/bin"
  elif [ "$(os_name)" = "alpine" ]; then
    bind_dir="/usr/libexec/postgresql${major}"
  else
    bind_dir="/usr/lib/postgresql/${major}/bin"
  fi
  if [ ! -d "${bind_dir}" ]; then
    dt_warning ${fname} "The directory '${bind_dir}' doesn't exist. Maybe pg of version '${major}' hasn't been installed yet?"
  fi
  echo "${bind_dir}"
}

function pg_hba_conf() {
  local ctx major service
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  major=$(gvar ${ctx} MAJOR)
  service=$(gvar ${ctx} SERVICE)
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/${service}/pg_hba.conf"
  else
    echo "/etc/postgresql/${major}/main/pg_hba.conf"
  fi
}

function postgresql_conf() {
  local ctx major service
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  major=$(gvar ${ctx} MAJOR)
  service=$(gvar ${ctx} SERVICE)
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/${service}/postgresql.conf"
  else
    echo "/etc/postgresql/${major}/main/postgresql.conf"
  fi
}

function service() {
  local ctx major
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  major=$(gvar ${ctx} MAJOR)
  if [ "$(os_name)" = "macos" ]; then
    echo "postgresql@${major}"
  else
    echo "postgresql"
  fi
}

# ctx_service_pg && pg_install
function pg_install() {
  local fname ctx major
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  major=$(gvar ${ctx} MAJOR)
  service=$(gvar ${ctx} SERVICE)
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    dt_exec ${fname} "echo 'deb http://apt.postgresql.org/pub/repos/apt $(os_codename)-pgdg main' | ${SUDO} tee /etc/apt/sources.list.d/pgdg.list" || return $?
    dt_exec ${fname} "${SUDO} wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | ${SUDO} apt-key add -" || return $?
    dt_exec ${fname} "${SUDO} apt-get update" || return $?
    dt_exec ${fname} "${SUDO} apt-get -y install \
      postgresql-${major} \
      postgresql-server-dev-${major} \
      libpq-dev" || return $?
  elif [ "$(os_kernel)" = "Darwin" ]; then
    dt_exec ${fname} "brew install ${service}"
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function pg_add_path() {
  NPATH="${PATH}"
  echo "${NPATH}" | grep -E -s "^$(bin_dir)" 1>/dev/null 2>&1
  if [ $? != 0 ] && [ -n "$(bin_dir)" ]; then
    # Cut all duplicates of $(bin_dir) from NPATH
    NPATH="$(echo "${NPATH}" | sed -E -e ":label; s|(.*):$(bin_dir)(.*)|\1\2|g; t label;")"
    # Prepend $(bin_dir)
    echo "$(bin_dir):${NPATH}"
  else
    echo "${NPATH}"
  fi
}

function pg_hba_conf_add_policy() {
  local fname old_hash new_hash pg_hba_conf
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  pg_hba_conf=$(gvar ${ctx} PG_HBA_CONF)
  old_hash=$(${SUDO} sha256sum "${pg_hba_conf}" | cut -d' ' -f 1) || return $?
  dt_exec ${fname} "${SUDO} sed -i -E -e 's/^\s*#?\s*host\s+all\s+all\s+0.0.0.0\/0\s+md5\s*$/host all all 0.0.0.0\/0 md5/; t; \$a host all all 0.0.0.0\/0 md5' ${pg_hba_conf}" || return $?
  new_hash=$(${SUDO} sha256sum "${pg_hba_conf}" | cut -d' ' -f 1) || return $?
  if [ "${old_hash}" != "${new_hash}" ]; then
    dt_info ${fname} "${pg_hba_conf} is ${BOLD}is changed${RESET}"; return 59
  else
    dt_info ${fname} "${pg_hba_conf} is ${BOLD}not changed${RESET}"
  fi
}

function pg_conf_set_port() {
  local fname old_hash new_hash postgresql_conf
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  postgresql_conf=$(gvar ${ctx} POSTGRESQL_CONF)
  old_hash=$(${SUDO} sha256sum "${postgresql_conf}" | cut -d' ' -f 1) || return $?
  dt_exec ${fname} "${SUDO} sed -i -E -e 's/^\s*#?\s*(port\s*=\s*[0-9]+)\s*$/port = $(port)/; t; \$a port = $(port)' ${postgresql_conf}" || return $?
  new_hash=$(${SUDO} sha256sum "${postgresql_conf}" | cut -d' ' -f 1) || return $?
  if [ "${old_hash}" != "${new_hash}" ]; then
    dt_info ${fname} "${postgresql_conf} is ${BOLD}is changed${RESET}"; return 59
  else
    dt_info ${fname} "${postgresql_conf} is ${BOLD}not changed${RESET}"
  fi
}

function pg_prepare() {
  local changed
  pg_hba_conf_add_policy; if [ "$?" = 59 ]; then changed="y"; fi
  pg_conf_set_port; if [ "$?" = 59 ]; then changed="y"; fi
  if [ "${changed}" != "y" ]; then return 0; fi
  service_stop
}

function lsof_pg() {
  PORT=$(port); HOST=$(host)
  lsof_tcp
}

# OS service methods
function os_service_start() { dt_exec ${CTX} "$(os_service) start '$(service)'"; }
function os_service_stop() { dt_exec ${CTX} "$(os_service) stop '$(service)'"; }
function os_service_prepare() { dt_exec ${CTX} "pg_prepare"; }
function os_service_install() { dt_exec ${CTX} "pg_install"; }
function os_service_lsof() { dt_exec ${CTX} "lsof_pg"; }

#dt_register "${CTX}" "pg" "$(os_service_methods)"

function pg_vars() {
  local c=$1
  var $c MAJOR 17 && \
  var $c MINOR 5 && \
  var $c PGHOST "localhost" && \
  var $c PGPORT 5430 && \
  var $c SERVICE "$(service $c)" && \
  var $c BIN_DIR "$(bin_dir $c)" && \
  var $c PSQL "$(gvar $c BIN_DIR)/psql" && \
  var $c PG_CONFIG "$(gvar $c BIN_DIR)/pg_config" && \
  var $c PG_HBA_CONF "$(pg_hba_conf $c)" && \
  var $c POSTGRESQL_CONF "$(postgresql_conf $c)" && \
  var $c CONFIG_SHAREDIR "$(PG_CONFIG $c --sharedir)" && \
  var $c CONFIG_LIBDIR "$(PG_CONFIG $c --pkglibdir)"
}

function ctx_service_pg() {
  local ctx=$(dt_fname "${FUNCNAME[0]}" "$0")
  drop_ctx ${ctx} && \
  pg_vars ${ctx}
}

function ctx_service_pg_tetrix() {
  local ctx=$(dt_fname "${FUNCNAME[0]}" "$0")
  drop_ctx ${ctx} && \
  var ${ctx} PORT 7777 && \
  pg_vars ${ctx}
}
