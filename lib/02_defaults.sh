dt_paths() {
  export DTOOLS=$(realpath $(dirname "$(realpath $self)")/..) && \
  # Paths that depend on DTOOLS
  export DT_PROJECT=$(realpath "${DTOOLS}"/..)
  export DT_ARTEFACTS="${DTOOLS}/.artefacts"
  export DT_CORE=${DTOOLS}/core
  export DT_LOCALS=${DTOOLS}/locals
  export DT_STANDS=${DTOOLS}/stands
  export DT_VARS=${DTOOLS}/vars
  # Paths that depend on DT_ARTEFACTS
  export DT_LOGS="${DT_ARTEFACTS}/logs"
  export DT_REPORTS="${DT_ARTEFACTS}/reports"
  export DT_TOOLCHAIN=${DT_ARTEFACTS}/toolchain
  export DL="${DT_TOOLCHAIN}/dl"
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  if [ ! -d "${DT_REPORTS}" ]; then mkdir -p ${DT_REPORTS}; fi
  if [ ! -d "${DT_TOOLCHAIN}" ]; then mkdir -p ${DT_TOOLCHAIN}; fi
}

# By default: DT_SEVERITY >= 4 for debug
dt_defaults() {
  export DT_DRYRUN="n"
  export DT_ECHO="y"
  export DT_ECHO_COLOR="${YELLOW}"
  export DT_SEVERITY=4
  DT_STAND='n'
}

function dt_init() {
  local self_dir self
  if [ -n "${BASH_SOURCE}" ]; then local self="${BASH_SOURCE[0]}"; else local self="$1"; fi && \
  self_dir="$(dirname $(realpath "${self}"))" && \
  dt_paths && \
  dt_defaults && \
  logging_init && \
  dt_rc_load $(basename "${self_dir}") "${self_dir}" && \
#  . "${self_dir}/clickhouse/rc.sh" && \
  . "${self_dir}/pg/rc.sh" && \
#  . "${self_dir}/redis/rc.sh" && \
#  . "${self_dir}/rabbitmq/rc.sh" && \
#  . "${self_dir}/cargo/rc.sh" && \
#  . "${self_dir}/python/rc.sh" && \
#  . "${DT_TOOLS}/rc.sh" && \
#  . "${DT_STANDS}/rc.sh" && \
#  if [ -f "${DT_LOCALS}/rc.sh" ]; then . "${DT_LOCALS}/rc.sh" || return $?; fi && \
sqlite_init && \
#  . ${DTOOLS}/vars/vars.sh && \
#  dt_autocomplete && \

}
