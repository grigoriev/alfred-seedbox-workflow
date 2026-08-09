# Alfred Seedbox Workflow

![CI](https://github.com/grigoriev/alfred-seedbox-workflow/actions/workflows/ci.yml/badge.svg)
[![Release](https://img.shields.io/github/v/release/grigoriev/alfred-seedbox-workflow)](https://github.com/grigoriev/alfred-seedbox-workflow/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=grigoriev_alfred-seedbox-workflow&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=grigoriev_alfred-seedbox-workflow)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=grigoriev_alfred-seedbox-workflow&metric=coverage)](https://sonarcloud.io/summary/new_code?id=grigoriev_alfred-seedbox-workflow)

The Mac front-end for the seedbox to Plex pipeline: a thin Alfred workflow that
drives the [sb-ctrl](https://github.com/grigoriev/sb-ctrl) backend over its REST
API and renders the JSON. All logic and secrets live in sb-ctrl; this workflow
holds only the API URL and a bearer token.

The full design is in [SPEC.md](SPEC.md).

## Usage

Type `seedbox`:

- `seedbox` - list completed torrents on the seedbox, newest first,
  type-to-filter by name. Enter on a torrent opens the **Send-to-Plex wizard**:
  pick the TMDb match (movie / cartoon / series / cartoon-series is detected),
  and Enter starts the transfer. A notification fires when it is queued.
- `seedbox status` - transfer jobs (state, %, ETA).
- `seedbox >` - settings: set the API URL and token, check for updates.

If the server is not reachable (you are off the LAN and VPN), the list shows a
single "beaver unreachable" hint instead of hanging.

## Requirements

- The [sb-ctrl](https://github.com/grigoriev/sb-ctrl) backend running on the
  server, reachable over HTTPS (set the URL and token in `seedbox >`).
- Alfred 5 with the Powerpack.

## Development

```sh
make lint    # shellcheck
make test    # bats (curl and open are mocked)
make build   # produce Seedbox.alfredworkflow
```

Bash 3.2 compatible. Every Script Filter renders with a single `jq` pass over
the API's JSON.

## Status

Beta. Implemented over the REST API: the torrent list, the Send-to-Plex wizard
(TMDb match + transfer), the status view with notifications, settings, and
unreachable handling. Requires the [sb-ctrl](https://github.com/grigoriev/sb-ctrl)
backend deployed and reachable.
