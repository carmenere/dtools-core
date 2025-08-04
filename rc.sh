if [ -n "${BASH_SOURCE}" ]; then CORE_RC="${BASH_SOURCE[0]}"; else CORE_RC="$0"; fi && \
export CORE_RC=$(realpath "${CORE_RC}") && \
export CORE_RC_DIR="$(dirname "${CORE_RC}")" && \
echo "CORE_RC=${CORE_RC}" && \
. "${CORE_RC_DIR}/lib/rc.sh" && \

dt_init "${CORE_RC_DIR}"

err=$?

if [ "${err}" != 0 ]; then
  dt_error load "${BOLD}${RED}dt_init() exited with non zero code '${err}'!${RESET}"
fi
unset err

if [ "$(get_err_cnt)" -gt 0 ]; then
  dt_error load "${BOLD}${RED}$(get_err_cnt) errors have occured!${RESET}"
fi