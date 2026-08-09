#!/bin/bash

. src/workflow_handler.sh
. src/media.sh
. src/ssh.sh
. src/globals.sh

# Single entry point behind the "seedbox" keyword, calling the sb-pull agent on
# the server over SSH. Called two ways from Alfred:
#   list mode (Script Filter): . src/seedbox.sh list "{query}"
#   run mode  (Run Script):    . src/seedbox.sh run  "{query}"
#
# Query grammar:
#   seedbox <query>   -> completed torrents on the seedbox, filtered
#   seedbox status    -> transfer jobs
#   seedbox >         -> settings (SSH host, updates)

mode="$1"
query="$2"

# The transfer wizard (pick, classify, TMDb, transfer) arrives in a later phase.
render_list() {
  local filter="$1" items
  sb_call list || { get_json_results; return 0; }
  items="$(jq -c -f src/list-torrents.jq --arg q "$filter" \
    --arg icon_multi "$ICON_TV" --arg icon_file "$ICON_MOVIE" <<< "$SB_JSON" 2>/dev/null)"
  [[ -n "$items" ]] || items="[]"
  if [[ "$items" == "[]" ]]; then
    add_result "" "" "No completed torrents" "Nothing matches this query" "$ICON_MOVIE" "no"
    get_json_results
    return 0
  fi
  printf '{"items":%s}\n' "$(jq -c --argjson extra "$(get_json_results)" '$extra.items + .' <<< "$items")"
  return 0
}

render_status() {
  local items
  sb_call status || { get_json_results; return 0; }
  items="$(jq -c -f src/list-jobs.jq --arg icon "$ICON_STATUS" <<< "$SB_JSON" 2>/dev/null)"
  if [[ -z "$items" || "$items" == "[]" ]]; then
    add_result "" "" "No transfers" "Nothing is in flight" "$ICON_STATUS" "no"
    get_json_results
    return 0
  fi
  printf '{"items":%s}\n' "$items"
  return 0
}

# Run mode: dispatch the item action.
if [[ "$mode" == "run" ]]; then
  action="${query%% *}"
  payload="${query#"$action"}"
  payload="${payload# }"
  case "$action" in
    set-host)   edit_host ;;
    autoupdate) set_autoupdate "$payload" ;;
    http://*|https://*) autoupdate_clear; [[ -f src/update.sh ]] && . src/update.sh "$query" ;;
    *) : ;;
  esac
  exit
fi

# List mode: global commands.
if [[ "$query" == ">"* ]]; then
  sub="${query#>}"
  sub="${sub# }"
  if [[ "$sub" == update* ]]; then
    if [[ -f src/update.sh ]]; then
      . src/update.sh ""
    else
      add_result "" "" "Updater unavailable" "Rebuild the workflow bundle" "$ICON_UPDATE" "no"
      get_json_results
    fi
  else
    globals_menu "$sub"
  fi
  exit
fi

# List mode: transfer jobs.
if [[ "$query" == "status" || "$query" == status\ * ]]; then
  render_status
  exit
fi

# List mode: the torrent list.
if [[ -z "$query" ]]; then
  autoupdate_refresh
  autoupdate_banner
fi
render_list "$query"
