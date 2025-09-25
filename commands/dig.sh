if [ -n "${BASH_SOURCE}" ]; then self="${BASH_SOURCE[0]}"; else self="$0"; fi

# Put array "domains=(...)" in some .sh file, for example ~/Desktop/domains.sh
#domains=(
#  "google.com"
#  "youtube.com"
#  "yandex.ru"
#)

ulimit -n 200000
DOMAINS=~/Desktop/domains.sh
RESOLVED_DOMAINS=/tmp/resloved.txt

function load_domains() {
  . "${DOMAINS}"
}

function dig_async() {
  rm -f "${RESOLVED_DOMAINS}"
  for domain in "${domains[@]}"
  do
     dig +noall +answer "$domain" 1 >> "${RESOLVED_DOMAINS}" 2>&1 &
  done
}

function watch_jobs() {
  for i in $(seq 0 100); do
    N="$(jobs -l | wc -l | sed 's/^[ \t]*//')"
    echo "${N} jobs remaining, $(date)"
    if [ "${N}" = "0" ]; then break; fi
    sleep 1
  done
}

function count_resolved_ips() {
  grep -E '\d+\.\d+\.\d+\.\d+' "${RESOLVED_DOMAINS}" | cut -d 'A' -f 2 | tr -d '\t' | sort | uniq | wc -l
}

function list_resolved_ips() {
  grep -E '\d+\.\d+\.\d+\.\d+' "${RESOLVED_DOMAINS}" | cut -d 'A' -f 2 | tr -d '\t' | sort | uniq
}

