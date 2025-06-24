if [ -n "${BASH_SOURCE}" ]; then CORE_RC="${BASH_SOURCE[0]}"; else CORE_RC="$0"; fi && \
CORE_RC=$(realpath "${CORE_RC}")
echo "CORE_RC=${CORE_RC}"
. ""$(dirname "${CORE_RC}")"/lib.sh" && \
dt_init $0