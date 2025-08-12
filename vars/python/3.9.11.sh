. ${DT_VARS}/python/defaults.sh

SYS_PYTHON="$(bash -c 'which python3')"
#MAJOR="$("${SYS_PYTHON}" -c 'import sys; print(sys.version_info.major)')"
#MINOR="$("${SYS_PYTHON}" -c 'import sys; print(sys.version_info.minor)')"
#PATCH="$("${SYS_PYTHON}" -c 'import sys; print(sys.version_info.micro)')"
#PYTHON=${SYS_PYTHON}
MAJOR=3
MINOR=9
PATCH=11

PYTHON_VER=${MAJOR}.${MINOR}.${PATCH}
PYTHON="${DT_TOOLCHAIN}/py/${PYTHON_VER}/bin/python${MAJOR}.${MINOR}"

if [ "$(os_codename)" = "focal" ] || [ "$(os_name)" = "macos" ]; then
  WITH_OPENSSL="y"
  OPENSSL_RPATH="auto"
fi

REQUIREMENTS="${DT_VARS}/python/requirements/${PYTHON_VER}.txt"

py_paths
