. /Users/an.romanov/Projects/carmenere/tetrix/dtools/core/lib.sh
. /Users/an.romanov/Projects/carmenere/tetrix/dtools/core/os.sh
. /Users/an.romanov/Projects/carmenere/tetrix/dtools/core/profiles.sh
. /Users/an.romanov/Projects/carmenere/tetrix/dtools/core/colors.sh
. /Users/an.romanov/Projects/carmenere/tetrix/dtools/core/pg/client.sh
. /Users/an.romanov/Projects/carmenere/tetrix/dtools/core/pg/queries.sh

dt_defaults

export DT_PROFILES=(dev pg_host)
echo "DT_PROFILES=${DT_PROFILES}"

#sed -E -n -e 's/(.+)\s+\(\)\s+\{$/\1/p'
#ctx=\$([ -z "\$1" ] && echo "${ctx}" || echo "\$1");

#"postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"

function drop_all_funcs() {
  declare -f  | sed -E -n -e 's/(ctx_.+)\s+\(\)\s+\{$/\1/p' | while read var; do unset -f "${var}"; done
}

function list_all_funcs() {
  declare -f  | sed -E -n -e 's/(ctx_.+)\s+\(\)\s+\{$/\1/p'
}

# mpref - prefix of registered method
function mpref() {
  local prf
  if [ -n "$1" ]; then prf="$1__"; fi
  echo "${prf}"
}

function register() {
  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local ctx=$1
  local pctx=$2
  local bind=$3
  local bctx=${ctx}
  if [ "${bind}" = "p" ]; then bctx=${pctx}; fi
  local methods=($(echo "$4"))
  dt_debug ${fname} "ctx=${BOLD}${ctx}${RESET}, pctx=${BOLD}${pctx}${RESET}; methods=${methods}"
  local mp=$(mpref ${ctx})
  local pp=$(mpref ${pctx})
  for m in ${methods[@]}; do
    if ! declare -f ${mp}${m} >/dev/null 2>&1; then
      dt_debug ${fname} "${BOLD}REGISTER${RESET} function: ${BOLD}${mp}${m}${RESET}() { local ctx=$([ -z "$1" ] && echo "${bctx}" || echo "$1"); ${pp}${m} \${ctx}; }"
      eval "function ${mp}${m}() { local ctx=\$([ -z "\$1" ] && echo "${bctx}" || echo "\$1"); dt_debug ${mp}${m} "ctx=\${ctx}"; ${pp}${m} \${ctx}; }"
    else
      dt_debug ${fname} "Method ${BOLD}${mp}${m}${RESET} has already defined."
    fi
  done
}

########################################################################################################################

function pg_vars() {
  local vars=(bin_dir)
  vars+=(host)
  vars+=(major)
  vars+=(minor)
  vars+=(pg_config)
  vars+=(pg_hba_conf)
  vars+=(port)
  vars+=(postgresql_conf)
  vars+=(psql)
  vars+=(service)
  echo "${vars}"
}

function connurl_vars() {
  local vars=(database)
  vars+=(db_url)
  vars+=(host)
  vars+=(password)
  vars+=(port)
  vars+=(user)
  echo "${vars}"
}

########################################################################################################################
function host() { echo "localhost"; }
########################################################################################################################
function major() { echo "17"; }
function minor() { echo "5"; }
function port() { echo "5432"; }

function pg_config() {
  local p=$(mpref $1)
  echo "$(${p}bin_dir)/pg_config"
}

function psql() {
  local p=$(mpref $1)
  echo "$(${p}bin_dir)/psql"
}

function bin_dir() {
  local p=$(mpref $1)
  if [ "$(os_name)" = "macos" ]; then
    bind_dir="$(brew_prefix)/opt/postgresql@$(${p}major)/bin"
  elif [ "$(os_name)" = "alpine" ]; then
    bind_dir="/usr/libexec/postgresql$(${p}major)"
  else
    bind_dir="/usr/lib/postgresql/$(${p}major)/bin"
  fi
  if [ ! -d "${bind_dir}" ]; then
    dt_warning ${fname} "The directory '${bind_dir}' doesn't exist"
  fi
  echo "${bind_dir}"
}

function pg_hba_conf() {
  local p=$(mpref $1)
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/$(${p}service)/pg_hba.conf"
  else
    echo "/etc/postgresql/$(${p}major)/main/pg_hba.conf"
  fi
}

function postgresql_conf() {
  local p=$(mpref $1)
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/$(${p}service)/postgresql.conf"
  else
    echo "/etc/postgresql/$(${p}major)/main/postgresql.conf"
  fi
}

function service() {
  local p=$(mpref $1)
  if [ "$(os_name)" = "macos" ]; then
    echo "postgresql@$(${p}major)"
  else
    echo "postgresql"
  fi
}

########################################################################################################################
function db_url() {
  local p=$(mpref $1)
  dt_debug db_url "p=${p}"
  echo "postgres://$(${p}user):$(${p}password)@$(${p}host):$(${p}port)/$(${p}database)"
}
########################################################################################################################
function user() { echo "Anton"; }
function password() { echo "12345"; }
function database() { echo "fizzbazz"; }
########################################################################################################################

drop_all_funcs || return 99

#-----------------------------------------------------------------------------------------------------------------------
ctx=ctx_service_pg
p=$(mpref ${ctx})
function ${p}port() { echo 1111; }

register ${ctx} '' '' "$(pg_vars)"

#-----------------------------------------------------------------------------------------------------------------------
ctx=ctx_service_pg_tetrix
pctx=ctx_service_pg
p=$(mpref ${ctx})
function ${p}major() { echo 15; }
function ${p}minor() { echo 13; }
function ${p}port() { echo 2222; }

register ${ctx} ${pctx} '' "$(pg_vars)"

#-----------------------------------------------------------------------------------------------------------------------
ctx=ctx_docker_pg
p=$(mpref ${ctx})
function ${p}host() { echo "ctx_xxx_100"; }
function ${p}port() { echo 3333; }

register ${ctx} '' '' "$(pg_vars)"

#-----------------------------------------------------------------------------------------------------------------------
ctx=ctx_docker_pg_tetrix
pctx=ctx_service_pg
p=$(mpref ${ctx})
function ${p}port() { echo 4444; }

register ${ctx} ${pctx} '' "$(pg_vars)"

#-----------------------------------------------------------------------------------------------------------------------
ctx=ctx_connurl_pg
p=$(mpref ${ctx})
function ${p}password() { echo "postgres"; }
function ${p}database() { echo "postgres"; }
function ${p}user() {
  if [ "$(os_name)" = "macos" ]; then
    echo ${USER}
  else
    echo "postgres"
  fi
}

if [ "$(get_profile pg_docker)" = "pg_docker" ]; then
  register ${ctx} ctx_docker_pg 'p' "host port psql"
else
  register ${ctx} ctx_service_pg 'p' "host port psql"
fi
register ${ctx} '' '' "$(connurl_vars)"

#-----------------------------------------------------------------------------------------------------------------------
ctx=ctx_connurl_pg_tetrix
p=$(mpref ${ctx})
function ${p}password() { echo "qwerty"; }

if [ "$(get_profile pg_docker)" = "pg_docker" ]; then
  register ${ctx} ctx_docker_pg_tetrix 'p' "host port psql"
else
  register ${ctx} ctx_service_pg_tetrix 'p' "host port psql"
fi
register ${ctx} ctx_connurl_pg '' "$(connurl_vars)"

#-----------------------------------------------------------------------------------------------------------------------
