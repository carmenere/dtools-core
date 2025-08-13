VENV_PROMT="[venv]"
PIP_UPGRADE="pip wheel setuptools"
PIP_PREFER_BINARY="y"
OPENSSL_VER="1.1.1w"
OPENSSL_VER_MACOS="1.1"
WITH_OPENSSL="n"
WITH_OPTIMIZATIONS="y"
OPENSSL_DIR="$(openssl_dir)"
OPENSSL_RPATH="$(openssl_rpath)"

if [ "$(os_name)" = "macos" ]; then export CC="/usr/bin/clang"; fi
if [ "$(os_name)" = "macos" ]; then export CXX="/usr/bin/clang"; fi
if [ "$(os_name)" = "macos" ]; then export CPPFLAGS="-I$(brew --prefix libpq)/include -I$(brew --prefix openssl@1.1)/include"; fi
if [ "$(os_name)" = "macos" ]; then export LDFLAGS="-L$(brew --prefix libpq)/lib -L$(brew --prefix openssl@1.1)/lib"; fi
