m4_postgresql.conf() {( set -eu; . "${DT_VARS}/m4/$1/postgresql.conf.sh" && _m4 )}
m4_pg_hba.conf() {( set -eu; . "${DT_VARS}/m4/$1/pg_hba.conf.sh" && _m4 )}

pg_conn_url() { echo "postgres://${user}:${password}@${host}:${port}/${database}"; }

pg_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "postgresql@${MAJOR}"
  else
    echo "postgresql@${MAJOR}-main.service"
  fi
}

pg_postgresql.conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/${SERVICE}/postgresql.conf"
  else
    echo "/etc/postgresql/${MAJOR}/main/postgresql.conf"
  fi
}

pg_pg_hba.conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/${SERVICE}/pg_hba.conf"
  else
    echo "/etc/postgresql/${MAJOR}/main/pg_hba.conf"
  fi
}

pg_superuser() {
  if [ "$(os_name)" = "macos" ]; then
    echo "${USER}"
  else
    echo "postgres"
  fi
}

pg_bin_dir() {
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

pg_add_path() {
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

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_m4_pg() {
  local methods=()
  methods+=(m4_postgresql.conf)
  methods+=(m4_pg_hba.conf)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_m4_pg"