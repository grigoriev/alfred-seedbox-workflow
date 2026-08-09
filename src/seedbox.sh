#!/bin/bash

. src/workflow_handler.sh
. src/media.sh
. src/http.sh
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

# Reopen Alfred on a query so the wizard advances to the next step.
alfred_search() {
  local text="$1"
  osascript - "$text" <<'APPLESCRIPT'
on run argv
  tell application id "com.runningwithcrayons.Alfred" to search (item 1 of argv)
end run
APPLESCRIPT
  return 0
}

# Post a macOS notification.
notify() {
  local title="$1" message="$2"
  osascript -e "display notification \"$message\" with title \"$title\"" >/dev/null 2>&1
  return 0
}

render_list() {
  local filter="$1" items
  sb_call GET /torrents "" || { get_json_results; return 0; }
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
  sb_call GET /jobs "" || { get_json_results; return 0; }
  items="$(jq -c -f src/list-jobs.jq --arg icon "$ICON_STATUS" <<< "$SB_JSON" 2>/dev/null)"
  if [[ -z "$items" || "$items" == "[]" ]]; then
    add_result "" "" "No transfers" "Nothing is in flight" "$ICON_STATUS" "no"
    get_json_results
    return 0
  fi
  printf '{"items":%s}\n' "$items"
  return 0
}

# Step 2 of the wizard: TMDb candidates for a chosen torrent.
render_candidates() {
  local hash="$1" filter="$2" name enc items
  sb_call GET /torrents "" || { get_json_results; return 0; }
  name="$(printf '%s' "$SB_JSON" | jq -r --arg h "$hash" '.items[]? | select(.hash==$h) | .name' 2>/dev/null | head -1)"
  if [[ -z "$name" ]]; then
    add_result "" "" "Torrent not found" "It may have been removed" "$ICON_OFFLINE" "no"
    get_json_results
    return 0
  fi
  enc="$(jq -rn --arg s "$name" '$s|@uri')"
  sb_call GET "/search?name=$enc" "" || { get_json_results; return 0; }
  items="$(jq -c -f src/search-items.jq --arg q "$filter" --arg hash "$hash" \
    --arg icon_movie "$ICON_MOVIE" --arg icon_tv "$ICON_TV" <<< "$SB_JSON" 2>/dev/null)"
  [[ -n "$items" ]] || items="[]"
  if [[ "$items" == "[]" ]]; then
    add_result "" "" "No TMDb matches" "Refine the name on the server, or retry" "$ICON_MOVIE" "no"
    get_json_results
    return 0
  fi
  printf '{"items":%s}\n' "$items"
  return 0
}

# Start a transfer: "start <hash> <kind> <name...>".
wizard_start() {
  local rest="$1" hash kind name body
  hash="${rest%% *}"
  rest="${rest#"$hash"}"
  rest="${rest# }"
  kind="${rest%% *}"
  name="${rest#"$kind"}"
  name="${name# }"
  body="$(jq -cn --arg h "$hash" --arg k "$kind" --arg n "$name" \
    '{hash:$h, kind:$k, name:$n, collision:"overwrite"}')"
  if sb_call POST /jobs "$body"; then
    notify "Seedbox" "Transfer started: $name"
    alfred_search "seedbox status"
  else
    notify "Seedbox" "Failed to start the transfer"
  fi
  return 0
}

# Run mode: dispatch the item action.
if [[ "$mode" == "run" ]]; then
  action="${query%% *}"
  payload="${query#"$action"}"
  payload="${payload# }"
  case "$action" in
    wizard)     alfred_search "seedbox @$payload " ;;
    start)      wizard_start "$payload" ;;
    set-url)    edit_url ;;
    set-token)  edit_token ;;
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

# List mode: the wizard's candidate step for a chosen torrent.
if [[ "$query" == "@"* ]]; then
  rest="${query#@}"
  hash="${rest%% *}"
  cfilter="${rest#"$hash"}"
  cfilter="${cfilter# }"
  render_candidates "$hash" "$cfilter"
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
