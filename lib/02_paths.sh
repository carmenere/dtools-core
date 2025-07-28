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
