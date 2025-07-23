fname() {
  if [ -n "$1" ]; then echo "$1"; else echo "$2"; fi
}

dt_info() {
  DT_SEVERITY=4
  >&2 echo -e "${GREEN}${BOLD}[dtools][INFO][$1]${RESET} $2"
}

function dt_rc_load() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  description=$1
  dir=$2
  if [ -z "${description}" ]; then return 99; fi
  if [ -z "${dir}" ]; then return 99; fi
  dt_info ${fname} "Loading ${BOLD}$description${RESET} ... "
  for file in $(ls "${dir}"/*.sh | sort); do
    if [ "$(basename "${file}")" != "rc.sh"  ]; then
      dt_info ${fname} "Sourcing "$(dirname "${file}")/${BOLD}$(basename "${file}")${RESET}" ..."
      . "${file}" || return 55
      dt_info ${fname} "done.";
    fi
  done
}

function load() {
  if [ -n "${BASH_SOURCE}" ]; then local self="${BASH_SOURCE[0]}"; else local self="$1"; fi
  local self_dir="$(dirname $(realpath "${self}"))"

  dt_rc_load $(basename "${self_dir}") "${self_dir}"
}

load $0 || return $?

reinit_dtools() { . ${DTOOLS}/core/rc.sh; }