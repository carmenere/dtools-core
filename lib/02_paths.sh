dt_paths() {
  export DT_CORE="$1"
  export DTOOLS=$(realpath "${DT_CORE}/..") || return $?
  # Paths that depend on DTOOLS
  export DT_PROJECT=$(realpath "${DTOOLS}"/..)
  export DT_ARTEFACTS="${DTOOLS}/.artefacts"
  export DT_LOCAL_VARS=${DTOOLS}/locals
  export DT_VARS=${DTOOLS}/vars
  # Paths that depend on DT_ARTEFACTS
  export DT_LOGS="${DT_ARTEFACTS}/logs"
  export DT_REPORTS="${DT_ARTEFACTS}/reports"
  export DT_TOOLCHAIN=${DT_ARTEFACTS}/toolchain
  export DT_M4=${DTOOLS}/core/m4
  export DT_M4_OUT=${DT_ARTEFACTS}/m4
  export DL="${DT_TOOLCHAIN}/dl"
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  if [ ! -d "${DT_REPORTS}" ]; then mkdir -p ${DT_REPORTS}; fi
  if [ ! -d "${DT_TOOLCHAIN}" ]; then mkdir -p ${DT_TOOLCHAIN}; fi
  if [ ! -d "${DT_M4_OUT}" ]; then mkdir -p ${DT_M4_OUT}; fi
}
