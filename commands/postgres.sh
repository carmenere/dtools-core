m4_postgresql.conf() {
  ( set -eu; . "${DT_VARS}/m4/$1/postgresql.conf.sh" && _m4 )
}

function pg_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "postgresql@${MAJOR}"
  else
    echo "postgresql@${MAJOR}-main.service"
  fi
}

postgresql_conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/${SERVICE}/postgresql.conf"
  else
    echo "/etc/postgresql/${MAJOR}/main/postgresql.conf"
  fi
}

function pg_superuser() {
  if [ "$(os_name)" = "macos" ] && [ "$(mode)" = "host" ]; then
    echo "${USER}"
  else
    echo "postgres"
  fi
}

function bin_dir() {
  local fname=bin_dir
  if [ "$(os_name)" = "macos" ]; then
    bind_dir="$(brew_prefix)/opt/postgresql@${MAJOR}/bin"
  elif [ "$(os_name)" = "alpine" ]; then
    bind_dir="/usr/libexec/postgresql${MAJOR}"
  else
    bind_dir="/usr/lib/postgresql/${MAJOR}/bin"
  fi
  if [ ! -d "${bind_dir}" ]; then
    dt_warning ${fname} "The directory '${bind_dir}' doesn't exist"
  fi
  echo "${bind_dir}"
}

mode() {
  local fname=mode
  if [ "${MODE}" = "docker" ]; then
    echo "docker"
  elif [ "${MODE}" = "host" ]; then
    echo "host"
  else
    dt_error ${fname} "Unknown pg mode: MODE=${MODE}"
    return 99
  fi
}

##################################################### AUTOCOMPLETE #####################################################
function methods_m4() {
  local methods=()
  methods+=(m4_postgresql.conf)
  echo "${methods[@]}"
}

DT_AUTOCOMPLETE+=(methods_m4)
DT_AUTOCOMPLETIONS["methods_m4"]="pg"