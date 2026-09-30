# CLAUDE.md

Thin Alfred front-end for the seedbox to Plex pipeline. It calls the `sb-ctrl` REST API and renders the JSON.
All logic and secrets live in `sb-ctrl`. This workflow holds only the API URL and a bearer token.
Keyword: `seedbox`. Artifact: `Seedbox.alfredworkflow`. Status: beta.

## Layout

- `src/seedbox.sh` - the entry point. It takes `mode` (`list` for the Script Filter, `run` for the Run Script) and `query`.
- `src/http.sh` - the REST bridge: `api_base`, `api_token`, `sb_curl`, `sb_call`. All HTTP goes through it.
- `src/cache.sh` - the response cache under `$alfred_workflow_cache`.
- `src/globals.sh` - the `seedbox >` settings menu (`globals_menu`): API URL, token, updates.
- `src/list-torrents.jq`, `src/list-jobs.jq`, `src/search-items.jq` - extracted jq programs.
- `src/workflow_handler.sh` - shared JSON feedback helpers, identical in all sibling workflows.
- `src/media.sh` - icon paths. `icons/` holds the PNGs, built from Octicons.
- `src/update.sh`, `src/autoupdate.sh` - fetched at build time from `alfred-workflow-updater`. Gitignored, never committed.
- `info.plist` - Alfred objects and the workflow `version`.
- `SPEC.md` - the design. The server contract is `sb-ctrl/SPEC.md` in the `sb-ctrl` repo.
- `tests/http_tests.bats`, `tests/seedbox_tests.bats`, `tests/workflow_handler_tests.bats`. No `perf_tests.bats` yet.
- `tests/mocks/bin/` - fake `curl`, `open` and `osascript`.

## Commands

```sh
make lint       # ShellCheck seedbox.sh, http.sh, globals.sh, cache.sh in Docker
make test       # fetch the updater, then run bats tests (macOS)
make coverage   # bats under kcov in Docker, writes sonar-coverage.xml
make build      # fetch the updater, smoke-test it, zip Seedbox.alfredworkflow
make icons      # regenerate PNG icons from Octicons (macOS)
make clean      # remove the artifact, fetched updater and coverage
```

1. Install tools with `brew install bats-core jq`.
2. `make lint SHELLCHECK=shellcheck` uses a local ShellCheck instead of Docker.
3. `make test` needs network access, because it fetches the updater bundle first.
4. Tests override the backend with `SEEDBOX_API_BASE`, `SEEDBOX_API_TOKEN` and `SEEDBOX_CURL`.

## Constraints and conventions

- Scripts run under stock macOS `/bin/bash` 3.2.
- No bash 4+ features: no `mapfile`, `readarray`, `declare -A`, `${var,,}` or `${var^^}`.
- Check a construct with `/bin/bash -c '...'`. zsh and Homebrew bash 5 hide 3.2 gaps.
- No perl. Use `awk`, `sed`, `jq` or bash.
- No business logic here. rTorrent, TMDb and naming rules belong to `sb-ctrl`.
- Every request uses bounded timeouts (`-m 8 --connect-timeout 4`) and the bearer token header.
- An unreachable server yields one "beaver unreachable" item. It must never hang the Script Filter.
- Build Script Filter JSON with `add_result` and `get_json_results`, never by hand.
- Render each Script Filter with one `jq` pass over the API JSON.
- Put multi-line jq or awk programs in `src/*.jq` or `src/*.awk` and call them with `-f`.
- Settings and updates live behind the `seedbox >` menu. `globals_menu` calls the shared `autoupdate_menu`.
- Update logic lives only in `alfred-workflow-updater`. Never reimplement it here.
- SonarCloud shell rules: `[[ ]]` not `[ ]`, positional params into named lowercase `local`s, snake_case functions, explicit `return` at function end, a `*)` default in every `case`, HTTPS for `curl`.

## Review focus

Flag these in a pull request:

- Any bash 4+ feature, or any perl call.
- A new or changed function without a bats test. A bug fix without a test that fails before the fix.
- Unquoted variable expansions, especially torrent names, job ids and API paths.
- Untrusted text (torrent names, API messages) interpolated into an `osascript` string without escaping.
- The token leaking into output, logs, a URL or a committed file.
- A plain `http://` default, or a `curl` call outside `src/http.sh` or without timeouts.
- Logic that belongs to the `sb-ctrl` server, or a change to the API contract without a matching `sb-ctrl` change.
- `jq` or a subshell spawned inside a per-item loop.
- A multi-line jq or awk program embedded in `$(...)` instead of a `src/*.jq` or `src/*.awk` file.
- Hand-built JSON strings instead of `add_result` and `json_encode`.
- A test that hits a real server instead of the `curl` mock.
- A violation of the Sonar shell rules listed above.
- A new `src/*.sh` script that the `SCRIPTS` list in the Makefile does not lint.
- Update or autoupdate logic added here, or a committed `src/update.sh` or `src/autoupdate.sh`.
- A change to `.github/workflows/ci.yml`, `release.yml` or `bump-version.yml` in this repo only. These are byte-identical across all 8 Alfred repos.
- A user-facing change without an entry under `## [Unreleased]` in `CHANGELOG.md`.
- A behavior change without a README or `SPEC.md` update.

Commit, branch and pull request rules are in `CONTRIBUTING.md`.

## CI and release

- `ci.yml`: ShellCheck, actionlint and zizmor on Ubuntu, bats on `macos-latest`, the build, and a SonarCloud scan with kcov coverage.
- The version lives in `info.plist`. `make print-version` and `make set-version VERSION=x.y.z` read and write it.
- A maintainer runs **Bump Version & Release**. It cuts the `CHANGELOG.md` section and tags `v*`.
- `release.yml` builds with `CHECK_PROVENANCE=1`, attests the artifact, and publishes an immutable release.
