function bin_dir() {
  local fname ctx major bind_dir
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1
  major=$(gvar MAJOR ${ctx})

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
  ctx=$1
  major=$(gvar MAJOR ${ctx})
  service=$(gvar SERVICE ${ctx})
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/${service}/pg_hba.conf"
  else
    echo "/etc/postgresql/${major}/main/pg_hba.conf"
  fi
}

function postgresql_conf() {
  local ctx major service
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1
  major=$(gvar MAJOR ${ctx})
  service=$(gvar SERVICE ${ctx})
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/${service}/postgresql.conf"
  else
    echo "/etc/postgresql/${major}/main/postgresql.conf"
  fi
}

function service() {
  local ctx major
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1
  major=$(gvar MAJOR ${ctx})
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
  ctx=$1
  major=$(gvar MAJOR ${ctx})
  service=$(gvar SERVICE ${ctx})
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
  ctx=$1
  pg_hba_conf=$(gvar PG_HBA_CONF ${ctx})
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
  postgresql_conf=$(gvar POSTGRESQL_CONF ${ctx})
  old_hash=$(${SUDO} sha256sum "${postgresql_conf}" | cut -d' ' -f 1) || return $?
  dt_exec ${fname} "${SUDO} sed -i -E -e 's/^\s*#?\s*(port\s*=\s*[0-9]+)\s*$/port = $(port)/; t; \$a port = $(port)' ${postgresql_conf}" || return $?
  new_hash=$(${SUDO} sha256sum "${postgresql_conf}" | cut -d' ' -f 1) || return $?
  if [ "${old_hash}" != "${new_hash}" ]; then
    dt_info ${fname} "${postgresql_conf} is ${BOLD}is changed${RESET}"; return 59
  else
    dt_info ${fname} "${postgresql_conf} is ${BOLD}not changed${RESET}"
  fi
}

# OS service methods
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

function ctx_service_pg() {
  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  # c is send by parent and usen in function, but if function is called without ctx, c is empty
  # but we must pass ctx to set_vars, so save if in ctx
  c=$1; ctx=${c}; if [ -z "${ctx}" ]; then ctx=${fname}; if dt_cached ${ctx}; then return 0; fi; fi;
  local MAJOR=17
  local MINOR=5
  local PGHOST="localhost"
  local PGPORT=5430
  local SERVICE="$(service $c)"
  local BIN_DIR="$(bin_dir $c)"
  local PSQL="${BIN_DIR}/psql"
  local PG_CONFIG="${BIN_DIR}/pg_config"
  local PG_HBA_CONF="$(pg_hba_conf $c)"
  local POSTGRESQL_CONF="$(postgresql_conf $c)"
  if [ ! -x "${PG_CONFIG}" ]; then
    dt_warning ${fname} "The binary '${PG_CONFIG}' doesn't exist. Maybe pg of version '${MAJOR}' hasn't been installed yet?"
  else
    local CONFIG_SHAREDIR="$(${PG_CONFIG} --sharedir)"
    local CONFIG_LIBDIR="$(${PG_CONFIG} --pkglibdir)"
  fi
  local START_CMD="$(os_service) start '${SERVICE}'"
  local STOP_CMD="$(os_service) stop '${SERVICE}'"
  local PREPARE_CMD="pg_prepare"
  local INSTALL_CMD="pg_install"
  local LSOF_CMD="lsof_pg"

  set_vars ${ctx} "$(pg_vars) $(service_vars)"
}

dt_register "ctx_service_pg" "pg" "$(service_methods)"

#function ctx_service_pg_tetrix() {
#  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
#  c=$1; if [ -z "${c}" ]; then c=${fname}; if dt_cached ${c}; then return 0; fi; fi;
#  var ${c} PORT 7777
#  ctx_service_pg ${c} && dt_cache ${c}
#}
