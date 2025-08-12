#m4_json() {(
#  set -eu;
#  _m4_json $1
#)}
#_m4_json() {
#  M4_TVARS=${DT_M4}/curl/foo/vars.m4
#  M4_IN="${DT_M4}/curl/foo/$1"
#  M4_OUT=
#  declare -A envs
#  ENVS=()
#  _m4
#}

function curl_get() {(
  set -eu
  . ${DT_VARS}/curl/$1.sh
  curl -v -X GET ${URL} | jq '.'
)}

function curl_post() {
  set -eu
  . ${DT_VARS}/curl/$1.sh
  curl -v -X POST ${URL} | jq '.'
}

function curl_put() {
  set -eu
  . ${DT_VARS}/curl/$1.sh
  curl -v -X PUT ${URL} | jq '.'
}

function curl_delete() {
  set -eu
  . ${DT_VARS}/curl/$1.sh
  curl -v -X DELETE ${URL} | jq '.'
}

##################################################### AUTOCOMPLETE #####################################################
cmd_family_curl() {
  local methods=()
  methods+=(curl_get)
  methods+=(curl_post)
  methods+=(curl_put)
  methods+=(curl_delete)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_curl"
