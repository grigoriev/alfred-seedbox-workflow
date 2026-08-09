#!/usr/bin/env bats

# Unit tests for src/http.sh: URL/token resolution and the API call wrapper.

setup() {
  export PATH="$BATS_TEST_DIRNAME/mocks/bin:$PATH"
  export alfred_workflow_data="$BATS_TEST_TMPDIR/data"
  mkdir -p "$alfred_workflow_data"
  export SEEDBOX_CURL="$BATS_TEST_DIRNAME/mocks/bin/curl"
}

@test "http.sh: api_base falls back to the default" {
  run bash -c 'unset SEEDBOX_API_BASE; . src/http.sh; api_base'
  [ "$output" = "https://beaver.h.g7v.io" ]
}

@test "http.sh: api_base honors the env override" {
  run bash -c 'export SEEDBOX_API_BASE=https://x; . src/http.sh; api_base'
  [ "$output" = "https://x" ]
}

@test "http.sh: api_base reads the config file, ignoring comments" {
  printf '# comment\n\nhttps://configured\n' > "$alfred_workflow_data/api-url"
  run bash -c '. src/http.sh; api_base'
  [ "$output" = "https://configured" ]
}

@test "http.sh: api_token reads the config file" {
  printf 'tok-123\n' > "$alfred_workflow_data/api-token"
  run bash -c '. src/http.sh; api_token'
  [ "$output" = "tok-123" ]
}

@test "http.sh: sb_curl prints the body and a trailing status" {
  run bash -c '. src/http.sh; sb_curl GET /jobs ""'
  echo "$output" | tail -1 | grep -q '200'
  echo "$output" | head -1 | jq -e 'has("jobs")' >/dev/null
}
