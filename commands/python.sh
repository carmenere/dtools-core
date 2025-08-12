openssl_dir() {
  if [ "$(os_name)" != "macos" ]; then
    echo "${DL}/.openssl-${OPENSSL_VER}"
  else
    echo "$(brew --prefix openssl@${OPENSSL_VER_MACOS})"
  fi
}

openssl_rpath() { if [ "$(os_name)" = "macos" ]; then echo "auto"; fi; }

configure_openssl_dir() { if [ -n "${OPENSSL_DIR}" ]; then echo "--openssldir='${OPENSSL_DIR}'"; fi; }
configure_openssl_prefix() { if [ -n "${OPENSSL_DIR}" ]; then echo "--prefix='${OPENSSL_DIR}'"; fi; }

openssl_build_opts() {
  local OPTS=()
  OPTS+=($(configure_openssl_dir))
  OPTS+=($(configure_openssl_prefix))
  echo "${OPTS}"
}

configure_py_prefix() { if [ -n "${PY_PREFIX}" ]; then echo "--prefix='${PY_PREFIX}'"; fi; }
configure_py_with_optimizations() { if [ "${WITH_OPTIMIZATIONS}" = "y" ]; then echo "--enable-optimizations"; fi; }
configure_py_with_openssl_dir() { if [ -n "${OPENSSL_DIR}" ] && [ "${WITH_OPENSSL}" = "y" ]; then echo "--with-openssl='${OPENSSL_DIR}'"; fi; }
configure_py_with_openssl_rpath() { if [ -n "${OPENSSL_RPATH}" ] && [ "${WITH_OPENSSL}" = "y" ]; then echo "--with-openssl-rpath='${OPENSSL_RPATH}'"; fi; }

py_build_opts() {
  local OPTS=()
  OPTS+=($(configure_py_prefix))
  OPTS+=($(configure_py_with_optimizations))
  OPTS+=($(configure_py_with_openssl_dir))
  OPTS+=($(configure_py_with_openssl_rpath))
  echo "${OPTS}"
}

pip_upgrade() { if [ -n "${PIP_UPGRADE}" ]; then echo "--upgrade ${PIP_UPGRADE}"; fi; }
pip_prefer_binary() { if [ "${PIP_PREFER_BINARY}" = "y" ]; then echo "--prefer-binary"; fi; }

pip_opts() {
  local OPTS=()
  OPTS+=($(pip_upgrade))
  OPTS+=($(pip_prefer_binary))
  echo "${OPTS}"
}

build_openssl() {
  local fname=build_openssl
  if [ -f "${OPENSSL_DIR}/bin/openssl" ]; then dt_warning ${fname} "File ${BOLD}${OPENSSL_DIR}/bin/openssl${RESET} exists, skip build"; return 0; fi
  if [ ! -d "${DL}" ]; then exec_cmd mkdir -p "${DL}" || return $?; fi
  if [ ! -f "${DL}/openssl-${OPENSSL_VER}.tar.gz" ]; then exec_cmd wget "${SSL_DOWNLOAD_URL}" --directory-prefix="${DL}" || return $?; fi
  if [ ! -d "${OPENSSL_DIR}" ]; then exec_cmd tar -zxf "${DL}/openssl-${OPENSSL_VER}.tar.gz" -C "${DL}" || return $?; fi
  exec_cmd cd ${DL}/openssl-${OPENSSL_VER}
  exec_cmd ./config $(openssl_build_opts)
    make
    make install
}

download_py_tar() {
  local fname=download_py_tar
  if [ -f "${DL}/${TAR}" ]; then dt_info ${fname} "File ${BOLD}${DL}/${TAR}${RESET} exists, skip download"; return 0; fi
  if [ ! -d "${DL}" ]; then exec_cmd mkdir -p ${DL}; fi
  exec_cmd cd ${DL}
  exec_cmd wget ${PY_DOWNLOAD_URL}
}

build_python() {
  local fname=build_python
  local BUILD_OPTS=()
  if [ -f "${PYTHON}" ]; then dt_warning ${fname} "File ${BOLD}${PYTHON}${RESET} exists, skip build"; return 0; fi
  download_py_tar
  if [ ! -d "${SRC}" ]; then exec_cmd tar -xf "${DL}/${TAR}" -C "${DL}" || return $?; fi
  if [ ! -d "${PY_PREFIX}" ]; then exec_cmd mkdir -p "${PY_PREFIX}" || return $?; fi
  exec_cmd cd ${SRC}
  exec_cmd ./configure $(py_build_opts)
    make -j $(nproc)
    sudo make altinstall
  cd -
}

vpython() {(
  set -eu; . "${DT_VARS}/python/$1.sh"
  exec_cmd ${VPYTHON}
)}

python_build() {(
  set -eu; . "${DT_VARS}/python/$1.sh"
  local pwd=$(pwd)
  if [ "${WITH_OPENSSL}" = "y" ]; then build_openssl || return $?; fi
  build_python &&
  exec_cmd cd ${pwd}
)}

python_clean() {(
  set -eu; . "${DT_VARS}/python/$1.sh"
  exec_cmd sudo rm -rf ${SRC}
  exec_cmd sudo rm -rf ${PY_PREFIX}
)}

venv_init() {(
  set -eu; . "${DT_VARS}/python/$1.sh"
  python_build $1
  if [ -f "${VPYTHON}" ]; then exec_cmd return 0; fi
  if [ ! -d "${VENV_DIR}" ]; then exec_cmd mkdir -p "${VENV_DIR}" || return $?; fi
  exec_cmd "${PYTHON}" -m venv --prompt='${VENV_PROMT}' "${VENV_DIR}"
)}

venv_clean() {(
  set -eu; . "${DT_VARS}/python/$1.sh"
  if [ -d ${VENV_DIR} ]; then exec_cmd rm -Rf ${VENV_DIR}; fi
)}

pip_init() {(
  set -eu; . "${DT_VARS}/python/$1.sh"
  echo "REQUIREMENTS=${REQUIREMENTS}"
  if [ -n "${REQUIREMENTS}" ]; then
    venv_init $1
    exec_cmd ${PIP} install -r ${REQUIREMENTS} $(pip_opts)
  fi
)}

pip_clean() {(
  set -eu; . "${DT_VARS}/python/$1.sh"
  if [ -f "${REQUIREMENTS}" ]; then exec_cmd ${PIP} uninstall -r ${REQUIREMENTS} -y; fi
)}

py_paths() {
  PY_PREFIX="${DT_TOOLCHAIN}/py/${PYTHON_VER}"
  TAR="Python-${PYTHON_VER}.tgz"
  SRC="${DL}/Python-${PYTHON_VER}"
  EXE="${DL}/Python-${PYTHON_VER}/.py-${PYTHON_VER}"
    # depends on TAR
  PY_DOWNLOAD_URL="https://www.python.org/ftp/python/${PYTHON_VER}/${TAR}"
  SSL_DOWNLOAD_URL="https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz"
  VENV_DIR="${DT_TOOLCHAIN}/venv/${PYTHON_VER}"
    # depends on VENV_DIR
  VPYTHON="${VENV_DIR}/bin/python"
    # depends on VPYTHON
  PIP="${VPYTHON} -m pip"
}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_python() {
  local methods=()
  methods+=(python_build)
  methods+=(python_clean)
  methods+=(venv_init)
  methods+=(pip_init)
  methods+=(venv_clean)
  methods+=(pip_clean)
  methods+=(vpython)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_python"