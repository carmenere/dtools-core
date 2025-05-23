function postgis_install() {
  VERSION="3.3.3"
  LIBINTL_VERSION="0.24"
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      sudo apt install postgresql-${PG_MAJOR}-postgis-3
  elif [ "$(os_kernel)" = "Darwin" ]; then
      [ ! -d /tmp/postgis ] || sudo rm -rf /tmp/postgis
      sudo mkdir -p /tmp/postgis
      sudo chown ${USER}:admin /tmp/postgis
      cd /tmp
      [ -f "postgis-${VERSION}.tar.gz" ] || wget http://postgis.net/stuff/postgis-${VERSION}.tar.gz
      tar -xvzf postgis-${VERSION}.tar.gz -C postgis
      cd postgis/postgis-${VERSION}
      ./configure --with-projdir=/opt/homebrew/opt/proj \
                  --without-raster --without-protobuf \
                  --with-pgconfig="$(which pg_config)" \
                  "LDFLAGS=${LDFLAGS} -L/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION}/lib" \
                  "CFLAGS=-I/opt/homebrew/Cellar/gettext/${LIBINTL_VERSION}/include"
      make
      make install
  else
    echo "Unsupported OS: '$(os_kernel)'"; exit;
  fi
}
