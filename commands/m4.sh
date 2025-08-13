_m4() {
  if [ -n "${M4_OUT}" ]; then
    exec_cmd ""$(inline_envs)" m4 ${M4_TVARS} ${M4_IN} | ${SUDO} tee ${M4_OUT} >/dev/null"
  else
    exec_cmd ""$(inline_envs)" m4 ${M4_TVARS} ${M4_IN}"
  fi
}
