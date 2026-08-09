#!/bin/bash

# Global commands behind "seedbox >": set the SSH host and updates. Server
# settings (roots, perms, keys) live in sb-pull's config on the server.

. src/media.sh
. src/autoupdate.sh
. src/ssh.sh

seedbox_lower() {
  local text="$1"
  printf '%s' "$text" | tr '[:upper:]' '[:lower:]'
  return 0
}

# $1 token  $2 filter  $3 title  $4 subtitle  $5 arg  $6 valid  $7 icon  $8 autocomplete
global_item() {
  local token="$1" filter="$2" title="$3" subtitle="$4" arg="$5" valid="$6" icon="$7" auto="$8"
  case "$(seedbox_lower "$token")" in
    *"$(seedbox_lower "$filter")"*) add_result "" "$arg" "$title" "$subtitle" "$icon" "$valid" "$auto" ;;
    *) : ;;
  esac
  return 0
}

globals_menu() {
  local filter="$1"
  global_item "set ssh host" "$filter" "Set SSH host" "Current: $(ssh_host)" "set-host" "yes" "$ICON_GEAR" ""
  autoupdate_menu "$filter" "$ICON_UPDATE"
  get_json_results
  return 0
}

# Open the SSH-host config file in a text editor, seeding the default.
edit_host() {
  local file
  file="$(host_config)"
  mkdir -p "${alfred_workflow_data:-.}"
  [[ -f "$file" ]] || printf '%s\n' "${SEEDBOX_SSH_HOST:-beaver.h.g7v.io}" > "$file"
  open -e "$file"
  return 0
}
