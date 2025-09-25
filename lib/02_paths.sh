# Possible values for DT_PROFILE = { "local" | "ci" }

dt_paths() {
  export DT_CORE="$1"
  export DTOOLS=$(realpath "${DT_CORE}/..") || return $?
  export DT_PROJECT="$(realpath "${DTOOLS}/..")"
  export DT_ARTEFACTS="$(realpath "$(dt_mkdir "${DT_PROJECT}/.dtools")")"

  if ! export | grep -E '^(declare -x )?DT_PROFILE=' >/dev/null; then
    export DT_PROFILE="local"
  fi

  # Paths that depend on DTOOLS
  export DT_M4=${DTOOLS}/core/m4
  export DT_MOCKS=${DTOOLS}/mocks

  export DT_LOCAL_VARS=${DTOOLS}/locals
  export DT_VARS=${DTOOLS}/vars
  export DT_VARS=${DTOOLS}/vars

  export DT_LOGS="${DT_ARTEFACTS}/logs"
  export DT_REPORTS="${DT_ARTEFACTS}/reports"

  export DT_TOOLCHAIN=${DT_ARTEFACTS}/toolchain
  export DT_M4_OUT=${DT_ARTEFACTS}/m4

  # Paths that depend on DT_TOOLCHAIN
  export DT_DL="${DT_TOOLCHAIN}/dl"

  if [ ! -d "${DT_LOGS}" ]; then exec_cmd mkdir -p ${DT_LOGS}; fi
  if [ ! -d "${DT_REPORTS}" ]; then exec_cmd mkdir -p ${DT_REPORTS}; fi
  if [ ! -d "${DT_TOOLCHAIN}" ]; then exec_cmd mkdir -p ${DT_TOOLCHAIN}; fi
  if [ ! -d "${DT_M4_OUT}" ]; then exec_cmd mkdir -p ${DT_M4_OUT}; fi
  if [ ! -d "${DT_DL}" ]; then exec_cmd mkdir -p ${DT_DL}; fi
}

reinit_logs() {
  if [ -d "${DT_LOGS}" ]; then
    exec_cmd $(dt_sudo) rm -rf "${DT_LOGS}"
  fi
  exec_cmd mkdir -p "${DT_LOGS}"
}

reinit_reports() {
  if [ -d "${DT_REPORTS}" ]; then
    exec_cmd $(dt_sudo) rm -rf "${DT_REPORTS}"
  fi
  exec_cmd mkdir -p "${DT_REPORTS}"
}
