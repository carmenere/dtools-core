function postgis_install() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  VERSION="3.3.3"
  LIBINTL_VERSION="0.24"
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    ${SUDO} apt install postgresql-${MAJOR}-postgis-3
  elif [ "$(os_kernel)" = "Darwin" ]; then
    [ ! -d /tmp/postgis ] || ${SUDO} rm -rf /tmp/postgis
    ${SUDO} mkdir -p /tmp/postgis
    ${SUDO} chown ${USER}:admin /tmp/postgis
    cd /tmp
    [ -f "postgis-${VERSION}.tar.gz" ] || wget http://postgis.net/stuff/postgis-${VERSION}.tar.gz
    tar -xvzf postgis-${VERSION}.tar.gz -C postgis
    cd postgis/postgis-${VERSION}
    ./configure --with-projdir=/opt/homebrew/opt/proj \
                --without-raster --without-protobuf \
                --with-pgconfig="${PG_CONFIG}" \
                "LDFLAGS=${LDFLAGS} -L/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION}/lib" \
                "CFLAGS=-I/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION}/include"
    make
    make install
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function postgis_install() {
  push_ctx ctx_service_pg || return $?
  postgis_install && pop_ctx
}