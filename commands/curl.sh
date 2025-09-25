dt_curl_inline_headers() {
  local result header
  result=()
  for header in "${HEADERS[@]}"; do
    result+=("-H \"${header}\"")
  done
  echo "${result[@]}"
}

function dt_curl() {(
    set -eu
    local fname=dt_curl
    scenario=$1; shift
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --chunk-id=*)
            local chunk_id="${1#*=}"; shift
            ;;
        --req=*)
            local req="${1#*=}"; shift
            ;;
        --resp=*)
            local resp="${1#*=}"; shift
            ;;
        --headers=*)
            local headers="${1#*=}"; shift
            ;;
        --method=*)
            local method="${1#*=}"; shift
            ;;
        --url=*)
            local url="${1#*=}"; shift
            ;;
        --query=*)
            local query="${1#*=}"; shift
            ;;
        --echo-resp=*)
            local echo_resp="${1#*=}"; shift
            ;;
        --chunk-size=*)
            chunk_size="${1#*=}"; shift
            ;;
        --chunks=*)
            chunks="${1#*=}"; shift
            ;;
        --tee=*)
            tee="${1#*=}"; shift
            ;;
        *)
            dt_error ${fname} "Unknown argument: $1"; shift
            ;;
      esac
    done
    set -eu
    . "${DT_VARS}/curl/${scenario}.sh"
    if [ -n "${chunk_size+set_or_not_null}" ]; then CHUNK_SIZE=${chunk_size}; fi
    if [ -n "${tee+set_or_not_null}" ] && [ "${tee}" = "y" ]; then LOG=${DT_REPORTS}/dt_curl/${scenario}.req.${METHOD}.log; else LOG=; fi
    if [ -n "${chunk_id+set_or_not_null}" ]; then CHUNK_ID=${chunk_id}; else CHUNK_ID=1; fi
    if [ -n "${headers+set_or_not_null}" ]; then HEADERS=${headers}; else HEADERS="$(dt_curl_inline_headers)"; fi
    if [ -n "${method+set_or_not_null}" ]; then METHOD=${method}; else METHOD="GET"; fi
    if [ -n "${req+set_or_not_null}" ]; then REQUEST=${req}; else REQUEST=; fi
    if [ -n "${resp+set_or_not_null}" ]; then RESPONSE=${resp}; else RESPONSE=; fi
    if [ -n "${url+set_or_not_null}" ]; then URL=${url}; fi
    if [ -n "${QUERY+set_or_not_null}" ]; then QUERY="${QUERY[@]}"; else QUERY=; fi
    if [ -n "${query+set_or_not_null}" ]; then QUERY=${query}; fi
    if [ -n "${echo_resp+set_or_not_null}" ]; then CURL_ECHO_RESP=${echo_resp}; else CURL_ECHO_RESP="y"; fi
    if [ -f "${REQUEST}" ]; then BODY="--data-binary '@${REQUEST}'"; else 
        if [ ${METHOD} = "POST" ] || [ ${METHOD} = "PUT" ] || [ ${METHOD} = "PATCH" ] || [ ${METHOD} = "DELETE" ]; then
            dt_warning ${fname} "File ${BOLD}${REQUEST}${RESET} doesn't exist"
        fi
        BODY=
    fi
    if [ -n "${RESPONSE}" ]; then RESPONSE="-o '${RESPONSE}'"; fi
    mkdir -p ${DT_REPORTS}/dt_curl
    if [ -n "${LOG}" ]; then
        exec_cmd curl --fail "${RESPONSE}" -v -w "$'%{stderr}\nStatus: %{http_code}\nTotal Time: %{time_total}s\n'" \
            -X ${METHOD} ${HEADERS} ${URL}${QUERY} ${BODY} 2\>\&1 \| tee -a "${LOG}"
    else
        exec_cmd curl --fail "${RESPONSE}" -v -w "$'%{stderr}\nStatus: %{http_code}\nTotal Time: %{time_total}s\n\n'" \
            -X ${METHOD} ${HEADERS} ${URL}${QUERY} ${BODY} | jq '.'
    fi

    if [ "${CURL_ECHO_RESP}" = "y" ] && [ -f "${RESPONSE}" ]; then
      exec_cmd jq "$'.'" "${RESPONSE}"
    fi
)}

##################################################### AUTOCOMPLETE #####################################################
cmd_family_curl() {
  local methods=()
  methods+=(dt_curl)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_curl"