function profile_dev() {
  DT_PROFILES+=("dev")
}

function profile_ci_tests() {
  DT_PROFILES+=("ci_tests")
}

function profile_release() {
  DT_PROFILES+=("release")
}

# Each profile name has format profile_%PROFILE%
# Each profile has corresponding function that just adds %PROFILE% to DT_PROFILES.
# The profile_dev is default profile.


# If requested profile is activated - just returns it back.
# Otherwise returns nothing.
function get_profile() {
  local fname profile rezult; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "DT_PROFILES=${DT_PROFILES}"
  profile="$1"; rezult=
  if [ -z "${profile}" ]; then echo "Profile was not provided."; return 99; fi
  for p in ${DT_PROFILES[@]};  do
    if [ "$p" = "$profile" ]; then
      dt_debug ${fname} "${BOLD}Profile${RESET}=${p}"
      rezult="$profile"
      break
    fi
  done
  echo "$rezult"
}