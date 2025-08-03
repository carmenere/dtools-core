fname() {
  if [ -n "$1" ]; then echo "$1"; else echo "$2"; fi
}

# It doesn't depend on DT_SEVERITY: if DT_SEVERITY=0 only "dt_log" messages are printed out
dt_log() {
  >&2 echo -e "${BOLD}[dtools][LOG][$1]${RESET} $2"
}

function dt_rc_load() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  description=$1
  dir=$2
  if [ -z "${description}" ]; then return 99; fi
  if [ -z "${dir}" ]; then return 99; fi
  dt_log ${fname} "Loading ${BOLD}$description${RESET} ... "
  for file in $(ls "${dir}"/*.sh | sort); do
    if [ "$(basename "${file}")" != "rc.sh"  ] && [ "$(basename "${file}")" != "03_tables.sh"  ]; then
      dt_log ${fname} "Sourcing "$(dirname "${file}")/${BOLD}$(basename "${file}")${RESET}" ..."
      . "${file}" || return 55
      dt_log ${fname} "done.";
    fi
  done
}

function load() {
  if [ -n "${BASH_SOURCE}" ]; then local self="${BASH_SOURCE[0]}"; else local self="$1"; fi
  local self_dir="$(dirname $(realpath "${self}"))"

  dt_rc_load $(basename "${self_dir}") "${self_dir}"
}

load $0 || return $?

if [ -f "${DTOOLS}/core/rc.sh" ]; then reinit_dtools() { . ${DTOOLS}/core/rc.sh; }; fi