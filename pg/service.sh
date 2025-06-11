function BIN_DIR() {
  local fname c major bind_dir
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  c=$1
  major=$(gvar MAJOR ${c})
  if [ "$(os_name)" = "macos" ]; then
    bind_dir="$(brew_prefix)/opt/postgresql@${major}/bin"
  elif [ "$(os_name)" = "alpine" ]; then
    bind_dir="/usr/libexec/postgresql${major}"
  else
    bind_dir="/usr/lib/postgresql/${major}/bin"
  fi
  if [ ! -d "${bind_dir}" ]; then
    dt_warning ${fname} "The directory '${bind_dir}' doesn't exist"
  fi
  echo "${bind_dir}"
}

function PG_HBA_CONF() {
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

function POSTGRESQL_CONF() {
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

function SERVICE() {
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

# $pctx is a parent ctx
# $ctx is a local ctx
# Vars "c" and "ctx" is NOT local! They are from caller!
function ctx_root() {
  local fname; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  cctx=$1
  pctx=$2
  if [ -n "${cctx}" ]; then ctx=${cctx}; fi
  if [ -n "${pctx}" ] && [ -n "${cctx}" ]; then merge="y"
  elif [ -z "${pctx}" ] && [ -z "${cctx}" ]; then merge="n"
  else dt_error ${fname} "pctx and cctx must be both defined or both null"; return 99; fi
  # If "$pctx" was NOT provided, then set "$pctx" to local "$ctx"
  if [ -z "${pctx}" ]; then
    pctx=${ctx}
    # If local $ctx has already cached - skip

    DT_CTX_VARS=()
  fi
  c=${ctx}
}

function merge_service_pg() {
  ctx_service_pg $1 $2
}

# "c" is a parent ctx.
# "ctx" is a local ctx, name of current function.
# If parent "ctx" was not provided, "c" is equal to "ctx".
function ctx_service_pg() {
  local ctx pctx cctx merge
  ctx_root $@
  ctx=$(dt_fname "${FUNCNAME[0]}" "$0")
  p=pctx
  if dt_cached ${ctx}; then return 0; fi
  echo "c=${c}, ctx=${ctx}"
  var MAJOR 17
  var MINOR 5
  var PGHOST "localhost"
  var PGPORT 5430
  var SERVICE service
  var BIN_DIR bin_dir
  var PSQL "%s/psql"
  var PG_CONFIG "%s/pg_config"
  PG_HBA_CONF $c
  POSTGRESQL_CONF $c
  if [ ! -x "${PG_CONFIG}" ]; then
    dt_warning ${fname} "The binary '${PG_CONFIG}' doesn't exist"
  else
    var CONFIG_SHAREDIR "$(${PG_CONFIG} --sharedir)"
    var CONFIG_LIBDIR "$(${PG_CONFIG} --pkglibdir)"
  fi
  var PREPARE_CMD "pg_prepare"
  var INSTALL_CMD "pg_install"
  var LSOF_CMD "lsof_pg"
  dt_cache $c
}

dt_register "ctx_service_pg" "pg" "$(service_methods)"

function ctx_service_pg_tetrix() {
  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  c=$1; if [ -z "${c}" ]; then c=${fname}; if dt_cached ${c}; then return 0; fi; fi;
  ctx_service_pg
  var ${c} PORT 7777
  $(v FOO ctx_service_pg)
  dt_cache ${c}
}

