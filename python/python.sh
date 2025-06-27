openssl_dir() {
  if [ "$(os_name)" != "macos" ]; then
    echo "${DL}/.openssl-$(OPENSSL_VER)"
  else
    echo "$(brew --prefix openssl@$(OPENSSL_VER_MACOS))"
  fi
}

openssl_rpath() { if [ "$(os_name)" = "macos" ]; then echo "auto"; fi; }

configure_openssl_dir() { if [ -n "$(OPENSSL_DIR)" ]; then echo "--openssldir='$(OPENSSL_DIR)'"; fi; }
configure_openssl_prefix() { if [ -n "$(OPENSSL_DIR)" ]; then echo "--prefix='$(OPENSSL_DIR)'"; fi; }

openssl_build_opts() {
  local OPTS=()
  OPTS+=($(configure_openssl_dir))
  OPTS+=($(configure_openssl_prefix))
  echo "${OPTS}"
}

configure_py_prefix() { if [ -n "$(PREFIX)" ]; then echo "--prefix='$(PREFIX)'"; fi; }
configure_py_with_optimizations() { if [ "$(WITH_OPTIMIZATIONS)" = "y" ]; then echo "--enable-optimizations"; fi; }
configure_py_with_openssl_dir() { if [ -n "$(OPENSSL_DIR)" ] && [ "$(WITH_OPENSSL)" = "y" ]; then echo "--with-openssl='$(OPENSSL_DIR)'"; fi; }
configure_py_with_openssl_rpath() { if [ -n "$(OPENSSL_RPATH)" ] && [ "$(WITH_OPENSSL)" = "y" ]; then echo "--with-openssl-rpath='$(OPENSSL_RPATH)'"; fi; }

py_build_opts() {
  local OPTS=()
  OPTS+=($(configure_py_prefix))
  OPTS+=($(configure_py_with_optimizations))
  OPTS+=($(configure_py_with_openssl_dir))
  OPTS+=($(configure_py_with_openssl_rpath))
  echo "${OPTS}"
}

pip_upgrade() { if [ -n "$(PIP_UPGRADE)" ]; then echo "--upgrade $(PIP_UPGRADE)"; fi; }
pip_prefer_binary() { if [ "$(PIP_PREFER_BINARY)" = "y" ]; then echo "--prefer-binary"; fi; }

pip_opts() {
  local OPTS=()
  OPTS+=($(pip_upgrade))
  OPTS+=($(pip_prefer_binary))
  echo "${OPTS}"
}

build_openssl() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -f "$(OPENSSL_DIR)/bin/openssl" ]; then dt_warning ${fname} "File ${BOLD}$(OPENSSL_DIR)/bin/openssl${RESET} exists, skip build"; return 0; fi && \
  if [ ! -d "${DL}" ]; then exec_cmd mkdir -p "${DL}" || return $?; fi && \
  if [ ! -f "${DL}/openssl-$(OPENSSL_VER).tar.gz" ]; then exec_cmd wget "$(SSL_DOWNLOAD_URL)" --directory-prefix="${DL}" || return $?; fi && \
  if [ ! -d "$(OPENSSL_DIR)" ]; then exec_cmd tar -zxf "${DL}/openssl-$(OPENSSL_VER).tar.gz" -C "${DL}" || return $?; fi && \
  exec_cmd cd ${DL}/openssl-$(OPENSSL_VER) && \
  exec_cmd ./config $(openssl_build_opts) && \
    make && \
    make install
}

download_py_tar() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -f "${DL}/$(TAR)" ]; then dt_info ${fname} "File ${BOLD}${DL}/$(TAR)${RESET} exists, skip download"; return 0; fi
  if [ ! -d "${DL}" ]; then exec_cmd mkdir -p ${DL}; fi && \
  exec_cmd cd ${DL} && \
  exec_cmd wget $(PY_DOWNLOAD_URL)
}

build_python() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local BUILD_OPTS=()
  if [ -f "$(PYTHON)" ]; then dt_warning ${fname} "File ${BOLD}$(PYTHON)${RESET} exists, skip build"; return 0; fi
  download_py_tar && \
  if [ ! -d "$(SRC)" ]; then exec_cmd tar -xf "${DL}/$(TAR)" -C "${DL}" || return $?; fi && \
  if [ ! -d "$(PREFIX)" ]; then exec_cmd mkdir -p "$(PREFIX)" || return $?; fi && \
  exec_cmd cd $(SRC) && \
  exec_cmd ./configure $(py_build_opts) && \
    make -j $(nproc) && \
    sudo make altinstall && \
  cd -
}

vpython() {
  exec_cmd $(VPYTHON)
}

python_build() {
  local pwd=$(pwd) && \
  if [ "$(WITH_OPENSSL)" = "y" ]; then build_openssl || return $?; fi && \
  build_python &&
  exec_cmd cd ${pwd}
}

venv_init() {
  if [ -f "$(VPYTHON)" ]; then exec_cmd return 0; fi
  if [ ! -d "$(VENV_DIR)" ]; then exec_cmd mkdir -p "$(VENV_DIR)" || return $?; fi
  exec_cmd "$(PYTHON)" -m venv --prompt='$(VENV_PROMT)' "$(VENV_DIR)"
}
venv_clean() { if [ -d $(VENV_DIR) ]; then exec_cmd rm -Rf $(VENV_DIR); fi; }

pip_init() { if [ -f "$(REQUIREMENTS)" ]; then
  ${self}__venv_init && \
  exec_cmd $(PIP) install -r $(REQUIREMENTS) $(pip_opts); fi
}
pip_clean() { if [ -f "$(REQUIREMENTS)" ]; then exec_cmd $(PIP) uninstall -r $(REQUIREMENTS) -y; fi; }

py_paths() {
  var PREFIX "${DT_TOOLCHAIN}/py/$(PYTHON_VER)"
  var TAR "Python-$(PYTHON_VER).tgz"
  var SRC "${DL}/Python-$(PYTHON_VER)"
  var EXE "${DL}/Python-$(PYTHON_VER)/.py-$(PYTHON_VER)"
  # depends on TAR
  var PY_DOWNLOAD_URL "https://www.python.org/ftp/python/$(PYTHON_VER)/$(TAR)"
  var SSL_DOWNLOAD_URL "https://www.openssl.org/source/openssl-$(OPENSSL_VER).tar.gz"
  var VENV_DIR "${DT_TOOLCHAIN}/venv/$(PYTHON_VER)"
  # depends on VENV_DIR
  var VPYTHON "$(VENV_DIR)/bin/python"
  # depends on VPYTHON
  var PIP "$(VPYTHON) -m pip"
}

function python_methods() {
  local methods=()
  methods+=(python_build)
  methods+=(venv_init)
  methods+=(pip_init)
  methods+=(venv_clean)
  methods+=(pip_clean)
  methods+=(vpython)
  echo "${methods[@]}"
}

ctx_python() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var DEFAULT_PYTHON "$(bash -c 'which python3')"
  var MAJOR "$("$(DEFAULT_PYTHON)" -c 'import sys; print(sys.version_info.major)')"
  var MINOR "$("$(DEFAULT_PYTHON)" -c 'import sys; print(sys.version_info.minor)')"
  var PATCH "$("$(DEFAULT_PYTHON)" -c 'import sys; print(sys.version_info.micro)')"
  var PYTHON $(DEFAULT_PYTHON)
  var PYTHON_VER $(MAJOR).$(MINOR).$(PATCH)
  var REQUIREMENTS "${DT_CORE}/python/requirements.txt"
  var VENV_PROMT "[venv]"
  var PIP_UPGRADE "pip wheel setuptools"
  var PIP_PREFER_BINARY "y"
  var OPENSSL_VER "1.1.1w"
  var OPENSSL_VER_MACOS "1.1"
  var WITH_OPENSSL "n"
  var WITH_OPTIMIZATIONS "y"
  var OPENSSL_DIR $(openssl_dir)
  var OPENSSL_RPATH $(openssl_rpath)
  if [ "$(os_name)" = "macos" ]; then export CC="/usr/bin/clang"; fi
  if [ "$(os_name)" = "macos" ]; then export CXX="/usr/bin/clang"; fi
  if [ "$(os_name)" = "macos" ]; then export CPPFLAGS="-I$(brew --prefix libpq)/include -I$(brew --prefix openssl@1.1)/include"; fi
  if [ "$(os_name)" = "macos" ]; then export LDFLAGS="-L$(brew --prefix libpq)/lib -L$(brew --prefix openssl@1.1)/lib"; fi
  py_paths
  cache_ctx
}

ctx_python_3_9_11() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var MAJOR 3
  var MINOR 9
  var PATCH 11
  var PYTHON_VER $(MAJOR).$(MINOR).$(PATCH)
  var PYTHON "${DT_TOOLCHAIN}/py/$(PYTHON_VER)/bin/python$(MAJOR).$(MINOR)"
  if [ "$(os_codename)" = "focal" ] || [ "$(os_name)" = "macos" ]; then
    var WITH_OPENSSL "y"
    var OPENSSL_RPATH "auto"
  fi
  ctx_python ${caller}
  cache_ctx
}

ctx_python_test() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  ctx_python ${caller}
  cache_ctx
}

DT_BINDINGS+=(ctx_python_3_9_11:3.9.11:python_methods)
DT_BINDINGS+=(ctx_python_test:test:python_methods)