install_postgis() {(
  set -eu
  local fname=postgis_install
  . "${DT_VARS}/services/$1.sh"

  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    exec_cmd ${SUDO} apt install postgresql-${MAJOR}-postgis-3
  elif [ "$(os_kernel)" = "Darwin" ]; then
    [ ! -d /tmp/postgis ] || exec_cmd ${SUDO} rm -rf /tmp/postgis
    if [ ! -d /opt/homebrew/Cellar/gettext/${LIBINTL_VERSION} ]; then
      dt_error ${fname} "/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION} doesn't exist"
    fi
    exec_cmd ${SUDO} mkdir -p /tmp/postgis
    exec_cmd ${SUDO} chown ${USER}:admin /tmp/postgis
    exec_cmd cd /tmp
    [ -f "postgis-${POSTGIS_VERSION}.tar.gz" ] || exec_cmd wget http://postgis.net/stuff/postgis-${POSTGIS_VERSION}.tar.gz
    exec_cmd tar -xvzf postgis-${POSTGIS_VERSION}.tar.gz -C postgis
    exec_cmd cd postgis/postgis-${POSTGIS_VERSION}

    local PG_CONFIG="$(pg_bin_dir)/pg_config"
    local PG_BINDIR="$(dirname "$(${PG_CONFIG} --bindir | tr ' ' '\n')")"
    local PG_LIBDIR="$(${PG_CONFIG} --pkglibdir | tr ' ' '\n')"
    export CXX="/usr/bin/clang"
    export CC="/usr/bin/clang"
    export DYLD_LIBRARY_PATH="${PG_LIBDIR}"
    export LD_LIBRARY_PATH="${PG_LIBDIR}"
    export LDFLAGS="-L/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION}/lib -L${PG_BINDIR}/lib"
    export CFLAGS="-I/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION}/include -I${PG_BINDIR}/include"
    export CPPFLAGS="-I/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION}/include -I${PG_BINDIR}/include"

    exec_cmd ./configure --with-projdir=/opt/homebrew/opt/proj --without-raster --without-protobuf \
                --with-pgconfig="${PG_CONFIG}"
    exec_cmd make
    exec_cmd make install
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"; return 99
  fi
)}
