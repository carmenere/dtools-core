function sql_click_create_user() {
  local query=$(
    escape_quote ""
  ) || return $?
  echo "${query}"
}

function sql_click_drop_user() {
  local query=$(
    escape_quote ""
  ) || return $?
  echo "${query}"
}

function sql_click_create_db() {
  local query=$(
    escape_quote ""
  ) || return $?
  echo "${query}"
}

function sql_click_drop_db() {
  local query=$(
    escape_quote ""
  ) || return $?
  echo "${query}"
}

function sql_click_grant_user() {
  local query=$(
    escape_quote ""
  ) || return $?
  echo "${query}"
}

function sql_click_revoke_user() {
  local query=$(
    escape_quote ""
  ) || return $?
  echo "${query}"
}