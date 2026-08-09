#!/usr/bin/env bats

# Integration tests for src/seedbox.sh. curl (to the sb-ctrl API) and open are
# mocked.

setup() {
  export PATH="$BATS_TEST_DIRNAME/mocks/bin:$PATH"
  export alfred_workflow_data="$BATS_TEST_TMPDIR/data"
  export alfred_workflow_cache="$BATS_TEST_TMPDIR/cache"
  mkdir -p "$alfred_workflow_data" "$alfred_workflow_cache"
  export SEEDBOX_CURL="$BATS_TEST_DIRNAME/mocks/bin/curl"
  export OPEN_LOG="$BATS_TEST_TMPDIR/open.log"
}

# --- list ------------------------------------------------------------------

@test "seedbox.sh: lists completed torrents" {
  run bash -c '. src/seedbox.sh list ""'
  echo "$output" | jq -e '[.items[].title] | index("Some.Movie.2024") != null and index("Some.Show.S01") != null' >/dev/null
}

@test "seedbox.sh: subtitle shows human size and kind" {
  run bash -c '. src/seedbox.sh list ""'
  echo "$output" | jq -e '.items[] | select(.title=="Some.Show.S01") | .subtitle | contains("10 GB") and contains("folder")' >/dev/null
}

@test "seedbox.sh: filters torrents by the query" {
  run bash -c '. src/seedbox.sh list "movie"'
  echo "$output" | jq -e '[.items[].title] == ["Some.Movie.2024"]' >/dev/null
}

@test "seedbox.sh: no match yields an empty-state item" {
  run bash -c '. src/seedbox.sh list "nomatch"'
  echo "$output" | jq -e '.items[0].title == "No completed torrents"' >/dev/null
}

# --- reachability ----------------------------------------------------------

@test "seedbox.sh: an unreachable server is reported" {
  SEEDBOX_HTTP_FAIL=1 run bash -c '. src/seedbox.sh list ""'
  echo "$output" | jq -e '.items[0].title == "beaver unreachable"' >/dev/null
}

@test "seedbox.sh: an API error is surfaced" {
  SEEDBOX_HTTP_CODE=500 run bash -c '. src/seedbox.sh list ""'
  echo "$output" | jq -e '.items[0].title == "sb-ctrl error (500)" and .items[0].subtitle == "boom"' >/dev/null
}

# --- status ----------------------------------------------------------------

@test "seedbox.sh: status with no jobs says so" {
  run bash -c '. src/seedbox.sh list "status"'
  echo "$output" | jq -e '.items[0].title == "No transfers"' >/dev/null
}

@test "seedbox.sh: status renders jobs" {
  export SEEDBOX_JOBS_JSON='{"jobs":[{"id":"001","name":"Movie","state":"active","pct":42,"eta":"3m"}]}'
  run bash -c '. src/seedbox.sh list "status"'
  echo "$output" | jq -e '.items[0].title == "Movie"' >/dev/null
  echo "$output" | jq -e '.items[0].subtitle | contains("active") and contains("42%") and contains("ETA 3m")' >/dev/null
}

# --- globals ---------------------------------------------------------------

@test "seedbox.sh: > lists the API settings and update commands" {
  run bash -c '. src/seedbox.sh list ">"'
  echo "$output" | jq -e '[.items[].title] | index("Set API URL") != null and index("Set API token") != null and index("Check for updates") != null' >/dev/null
}

@test "seedbox.sh: run set-url opens the url config" {
  run bash -c '. src/seedbox.sh run "set-url"'
  grep -q 'api-url' "$OPEN_LOG"
  [ -f "$alfred_workflow_data/api-url" ]
}

@test "seedbox.sh: run set-token opens the token config" {
  run bash -c '. src/seedbox.sh run "set-token"'
  grep -q 'api-token' "$OPEN_LOG"
  [ -f "$alfred_workflow_data/api-token" ]
}

@test "seedbox.sh: autoupdate on writes the flag" {
  run bash -c '. src/seedbox.sh run "autoupdate on"'
  [ -f "$alfred_workflow_data/autoupdate" ]
}

@test "seedbox.sh: > update runs the fetched updater" {
  run bash -c '. src/seedbox.sh list "> update"'
  echo "$output" | jq -e 'has("items")' >/dev/null
}

@test "seedbox.sh: run with a download url routes to the installer" {
  run bash -c '. src/seedbox.sh run "https://example.com/Seedbox.alfredworkflow"'
  [ "$status" -eq 0 ]
}
