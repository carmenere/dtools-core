function ctx_deps_ubuntu() {
  DEPS=()
  DEPS+=(coreutils)
  DEPS+=(build-essential)
  DEPS+=(direnv)
  DEPS+=(git)
  DEPS+=(iputils-ping)
  DEPS+=(jq)
  DEPS+=(libbz2-dev)
  DEPS+=(libffi-dev)
  DEPS+=(libpq-dev)
  DEPS+=(make)
  DEPS+=(pkg-config)
  DEPS+=(protobuf-compiler)
  DEPS+=(python3-dev)
  DEPS+=(python3-venv)
  DEPS+=(tmux)
  DEPS+=(vim)
  DEPS+=(wget)
  DEPS+=(zlib1g-dev)
  PACMAN="apt install -y"
}

# alpine: py3-pip py3-virtualenv python3-dev zlib-dev libffi-dev bzip2-dev

function ctx_deps_macos() {
  DEPS=()
  DEPS+=(gnu-sed)
  PACMAN="brew install"
}

function install_deps() {
  if [ "$(os_name)" = "ubuntu" ] || [ "$(os_name)" = "debian" ]; then
    target ctx_deps_ubuntu || return $?
  elif [ "$(os_name)" = "macos" ]; then
    target ctx_deps_macos || return $?
  fi

  if [ -z "${DEPS}" ]; then return 0; fi

  for dep in ${DEPS[@]}; do
    exec_cmd "${PACMAN} ${dep}"
  done
}
