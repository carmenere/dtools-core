postgis_install() {
  local fname=postgis_install
  VERSION="3.5.3"
  LIBINTL_VERSION="0.26"
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    exec_cmd ${SUDO} apt install postgresql-${MAJOR}-postgis-3
  elif [ "$(os_kernel)" = "Darwin" ]; then
    [ ! -d /tmp/postgis ] || ${SUDO} rm -rf /tmp/postgis
    if [ ! -d /opt/homebrew/Cellar/gettext/${LIBINTL_VERSION} ]; then
      dt_error ${fname} "/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION} doesn't exist"
    fi
    exec_cmd ${SUDO} mkdir -p /tmp/postgis
    exec_cmd ${SUDO} chown ${USER}:admin /tmp/postgis
    exec_cmd cd /tmp
    [ -f "postgis-${VERSION}.tar.gz" ] || exec_cmd wget http://postgis.net/stuff/postgis-${VERSION}.tar.gz
    exec_cmd tar -xvzf postgis-${VERSION}.tar.gz -C postgis
    exec_cmd cd postgis/postgis-${VERSION}
    exec_cmd ./configure --with-projdir=/opt/homebrew/opt/proj --without-raster --without-protobuf \
                --with-pgconfig="${PG_CONFIG}" \
                "LDFLAGS=\"-L/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION}/lib\"" \
                "CFLAGS=\"-I/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION}/include\""
    make
    make install
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}
