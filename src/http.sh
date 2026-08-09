#!/bin/bash

# REST bridge to the sb-ctrl backend. The Mac holds only the API base URL and a
# bearer token; all logic and secrets live on the server (see the project SPEC).

. src/cache.sh
. src/media.sh

# Path to the file holding the API base URL.
api_base_config() {
  printf '%s/api-url' "${alfred_workflow_data:-.}"
  return 0
}

# The configured API base URL, or the default. SEEDBOX_API_BASE overrides the
# default (used by tests).
api_base() {
  local file value=""
  file="$(api_base_config)"
  [[ -f "$file" ]] && value="$(grep -vE '^[[:space:]]*(#|$)' "$file" 2>/dev/null | head -1)"
  [[ -n "$value" ]] || value="${SEEDBOX_API_BASE:-https://beaver.h.g7v.io}"
  printf '%s' "$value"
  return 0
}

# Path to the file holding the bearer token.
api_token_config() {
  printf '%s/api-token' "${alfred_workflow_data:-.}"
  return 0
}

# The configured bearer token, or nothing.
api_token() {
  local file
  file="$(api_token_config)"
  [[ -f "$file" ]] || { printf '%s' "${SEEDBOX_API_TOKEN:-}"; return 0; }
  grep -vE '^[[:space:]]*(#|$)' "$file" 2>/dev/null | head -1
  return 0
}

# Perform a request; print the body and, on its own last line, the HTTP status.
# SEEDBOX_CURL overrides the curl binary (tests).
sb_curl() {
  local method="$1" path="$2" data="$3" curl_bin base token
  curl_bin="${SEEDBOX_CURL:-curl}"
  base="$(api_base)"
  token="$(api_token)"
  if [[ "$method" == "GET" ]]; then
    "$curl_bin" -sS -m 8 --connect-timeout 4 -H "Authorization: Bearer $token" \
      -w $'\n%{http_code}' "$base$path"
  else
    "$curl_bin" -sS -m 8 --connect-timeout 4 -X "$method" \
      -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
      -d "$data" -w $'\n%{http_code}' "$base$path"
  fi
  return $?
}

# Call the API, splitting body from status. On success sets SB_JSON and returns
# 0. On failure queues a single result: an unreachable server or an API error.
# $1 method  $2 path  $3 data
sb_call() {
  local out rc code body msg
  out="$(sb_curl "$1" "$2" "$3" 2>/dev/null)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    add_result "" "" "beaver unreachable" "Connect to VPN or LAN, then retry" "$ICON_OFFLINE" "no"
    return 1
  fi
  code="${out##*$'\n'}"
  body="${out%$'\n'*}"
  if [[ "$code" == 2* ]]; then
    # shellcheck disable=SC2034  # consumed by the sourcing script (seedbox.sh)
    SB_JSON="$body"
    return 0
  fi
  msg="$(printf '%s' "$body" | jq -r '.detail // .error // "request failed"' 2>/dev/null)"
  add_result "" "" "sb-ctrl error ($code)" "$msg" "$ICON_OFFLINE" "no"
  return 1
}
