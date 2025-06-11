function openssl_dir() {
  if [ "$(os_name)" != "macos" ]; then
    echo "${DL}/.openssl-${OPENSSL_VER}"
  else
    echo "$(brew --prefix openssl@1.1)"
  fi
}

function py_set_paths() {
  version="$1"
  if [ -z "${version}" ]; then dt_error "Var version is empty"; return 99; fi
  export PREFIX="${DT_TOOLCHAIN}/py/${version}"
  export TAR="Python-${version}.tgz"
  export SRC="${DL}/Python-${version}"
  export EXE="${DL}/Python-${version}/.py-${version}"
  # depends on TAR
  export DOWNLOAD_URL="https://www.python.org/ftp/python/${version}/${TAR}"
  export VENV_DIR="${DT_TOOLCHAIN}/venv/${version}"
  # depends on VENV_DIR
  export VPYTHON="${VENV_DIR}/bin/python"
  # depends on VPYTHON
  export PIP="${VPYTHON} -m pip"
}

function ctx_python() {
  export PYMAKE="${DT_CORE}/python/python.mk"
  export DL="${DT_TOOLCHAIN}/dl"

  export PYTHON="$(bash -c 'which python3')"
  export MAJOR="$("${PYTHON}" -c 'import sys; print(sys.version_info.major)')"
  export MINOR="$("${PYTHON}" -c 'import sys; print(sys.version_info.minor)')"
  export PATCH="$("${PYTHON}" -c 'import sys; print(sys.version_info.micro)')"

  py_set_paths "${MAJOR}.${MINOR}.${PATCH}"

  export REQUIREMENTS="${DT_CORE}/python/requirements.txt"
  export VENV_PROMT="[venv]"
  export UPGRADE="pip wheel setuptools"

  export OPENSSL_VER="1.1.1w"
  export WITH_OPENSSL="no"
  export WITH_OPTIMIZATIONS="yes"
  if [ "$(os_name)" = "macos" ]; then OPENSSL_RPATH="auto"; fi
  export OPENSSL_DIR="$(openssl_dir)"

  if [ "$(os_name)" = "macos" ]; then export CC="/usr/bin/clang"; fi
  if [ "$(os_name)" = "macos" ]; then export CXX="/usr/bin/clang"; fi
  if [ "$(os_name)" = "macos" ]; then export CPPFLAGS="-I$(brew --prefix libpq)/include -I$(brew --prefix openssl@1.1)/include"; fi
  if [ "$(os_name)" = "macos" ]; then export LDFLAGS="-L$(brew --prefix libpq)/lib -L$(brew --prefix openssl@1.1)/lib"; fi
}

function python_build() {
  export
  dt_exec ${fname} "make -f ${PYMAKE} python3"
}

function python_venv_init() {
    dt_exec ${fname} "make -f ${PYMAKE} venv-init"
}

function python_pip_init() {
  export SITE_PACKAGES="$("${VPYTHON}" -m pip show pip | grep Location | cut -d':' -f 2)"
  dt_exec ${fname} "make -f ${PYMAKE} pip-init"
}

function python_venv_clean() {
  dt_exec ${fname} "make -f ${PYMAKE} venv-clean"
}

function python_pip_clean() {
  export SITE_PACKAGES="$("${VPYTHON}" -m pip show pip | grep Location | cut -d':' -f 2)"
  dt_exec ${fname} "make -f ${PYMAKE} pip-clean"
}

function python_prepare() {
  python_build && \
  python_venv_init && \
  python_pip_init
}

function python_clean() {
  python_venv_clean
}

function ctx_python_3_9_11() {
  ctx_python
  MAJOR=3
  MINOR=9
  PATCH=11
  PY_VERSION="${MAJOR}.${MINOR}.${PATCH}"
  PYTHON="${DT_TOOLCHAIN}/py/${PY_VERSION}/bin/python${MAJOR}.${MINOR}"

  if [ "$(os_codename)" = "focal" ] || [ "$(os_name)" = "macos" ]; then
    WITH_OPENSSL="yes"
    OPENSSL_RPATH="auto"
  fi

  py_set_paths "${MAJOR}.${MINOR}.${PATCH}"
}
