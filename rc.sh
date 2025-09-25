get_err_cnt() { echo "$(. "${DT_ERR_COUNTER_PATH}" && echo "${DT_ERR_COUNTER}")"; }
inc_err_cnt() { DT_ERR_COUNTER=$(($(get_err_cnt)+1)); $(save_err_cnt); }
reset_err_cnt() { DT_ERR_COUNTER=0; $(save_err_cnt); }
save_err_cnt() { echo "DT_ERR_COUNTER=${DT_ERR_COUNTER}" > ${DT_ERR_COUNTER_PATH}; }

export DT_ERR_COUNTER_PATH="/tmp/dt_err_counter"
export DT_ERR_COUNTER=0
reset_err_cnt

if [ -n "${BASH_SOURCE}" ]; then CORE_RC="${BASH_SOURCE[0]}"; else CORE_RC="$0"; fi && \
export CORE_RC=$(realpath "${CORE_RC}") && \
export CORE_RC_DIR="$(dirname "${CORE_RC}")" && \
echo "CORE_RC=${CORE_RC}" && \
. "${CORE_RC_DIR}/lib/rc.sh" && \
dt_init "${CORE_RC_DIR}"
err=$?

if [ "${err}" != 0 ]; then
  dt_error load "dt_init() exited with non zero code ${BOLD}${RED}'${err}'${RESET}"
  dt_error load "Current file being load is ${BOLD}${RED}${DT_CURRENT_FILE_BEING_LOAD} ${RESET}"
fi
unset err

if [ "$(get_err_cnt)" -gt 0 ]; then
  dt_error load "${BOLD}${RED}$(get_err_cnt) errors${RESET} have occured!"
fi
