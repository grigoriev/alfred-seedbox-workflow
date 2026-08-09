#!/bin/bash

# SSH bridge to the sb-pull agent on the server. The Mac holds only the host;
# all logic and secrets live on the server (see the project SPEC).

. src/cache.sh
. src/media.sh

# Path to the file holding the SSH host (a single line).
host_config() {
  printf '%s/ssh-host' "${alfred_workflow_data:-.}"
  return 0
}

# The configured SSH host, or the default. SEEDBOX_SSH_HOST overrides the default
# (used by tests).
ssh_host() {
  local file host=""
  file="$(host_config)"
  [[ -f "$file" ]] && host="$(grep -vE '^[[:space:]]*(#|$)' "$file" 2>/dev/null | head -1)"
  [[ -n "$host" ]] || host="${SEEDBOX_SSH_HOST:-beaver.h.g7v.io}"
  printf '%s' "$host"
  return 0
}

# Run "sb-pull <args>" on the server, printing its stdout and returning its exit
# code. A fast ConnectTimeout and BatchMode mean an unreachable server fails
# quickly instead of hanging. SEEDBOX_SSH overrides the ssh binary (tests).
sb_pull() {
  local host ssh_bin
  host="$(ssh_host)"
  ssh_bin="${SEEDBOX_SSH:-ssh}"
  "$ssh_bin" -o BatchMode=yes -o ConnectTimeout=4 "$host" sb-pull "$@"
  return $?
}

# Call an sb-pull subcommand, capturing stdout+stderr. On failure, distinguish an
# sb-pull JSON error from an unreachable server, and queue a single result. Sets
# the global SB_JSON on success. Returns 1 when it queued an error.
sb_call() {
  local out rc err
  out="$(sb_pull "$@" 2>&1)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    err="$(printf '%s' "$out" | jq -r '.error // empty' 2>/dev/null)"
    if [[ -n "$err" ]]; then
      add_result "" "" "sb-pull error" "$err" "$ICON_OFFLINE" "no"
    else
      add_result "" "" "beaver unreachable" "Connect to VPN or LAN, then retry" "$ICON_OFFLINE" "no"
    fi
    return 1
  fi
  # shellcheck disable=SC2034  # consumed by the sourcing script (seedbox.sh)
  SB_JSON="$out"
  return 0
}
