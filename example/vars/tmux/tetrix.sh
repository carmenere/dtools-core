. ${DT_VARS}/tmux/defaults.sh

TMX_SESSION="tetrix"
TMX_WINDOW_NAME=$(. "${DT_VARS}"/apps/tetrix-api.sh && echo "APP=${APP}")
TMX_START_CMD=". ${DTOOLS}/core/rc.sh && app_start tetrix-api"
