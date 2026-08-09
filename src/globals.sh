#!/bin/bash

# Global commands behind "seedbox >": set the API URL and token, and updates.
# Server settings (roots, perms, keys) live in sb-ctrl's config on the server.

. src/media.sh
. src/autoupdate.sh
. src/http.sh

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
  global_item "set api url"   "$filter" "Set API URL"   "Current: $(api_base)" "set-url"   "yes" "$ICON_GEAR" ""
  global_item "set api token" "$filter" "Set API token" "Bearer token for sb-ctrl" "set-token" "yes" "$ICON_GEAR" ""
  autoupdate_menu "$filter" "$ICON_UPDATE"
  get_json_results
  return 0
}

# Open the API-URL config file in a text editor, seeding the default.
edit_url() {
  local file
  file="$(api_base_config)"
  mkdir -p "${alfred_workflow_data:-.}"
  [[ -f "$file" ]] || printf '%s\n' "${SEEDBOX_API_BASE:-https://beaver.h.g7v.io}" > "$file"
  open -e "$file"
  return 0
}

# Open the API-token config file in a text editor.
edit_token() {
  local file
  file="$(api_token_config)"
  mkdir -p "${alfred_workflow_data:-.}"
  [[ -f "$file" ]] || printf '# Paste the sb-ctrl bearer token here\n' > "$file"
  open -e "$file"
  return 0
}
