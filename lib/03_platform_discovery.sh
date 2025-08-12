function os_arch() {
  echo $(uname -m)
}

function os_kernel() {
  echo "$(uname -s)"
}

function os_name() {
  if [ "$(os_kernel)" = "Linux" ] && [ -f "/etc/os-release" ]; then
    echo $(. /etc/os-release && echo "${ID}")
  elif [ "$(os_kernel)" = "Darwin" ]; then
    echo "macos"
  fi
}

function os_codename() {
  if [ "$(os_kernel)" = "Linux" ] && [ -f "/etc/os-release" ]; then
    echo $(. /etc/os-release && echo "${VERSION_CODENAME}")
  fi
}

function brew_prefix() {
  echo $(brew --prefix)
}