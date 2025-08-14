_m4() {
  set -eu
  if [ -n "${M4_OUT}" ]; then
    exec_cmd ""$(inline_envs)" m4 ${M4_TVARS} ${M4_IN} > /tmp/.m4_tmp"
    err=$?
    if [ "${err}" != 0 ] ; then
      dt_error _m4 "m4 exited wit code ${err}"
      return ${err}
    fi
    exec_cmd ${SUDO} cp -f /tmp/.m4_tmp ${M4_OUT}
  else
    exec_cmd ""$(inline_envs)" m4 ${M4_TVARS} ${M4_IN}"
  fi
}
