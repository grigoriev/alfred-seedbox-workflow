# Alfred Seedbox Workflow

![CI](https://github.com/grigoriev/alfred-seedbox-workflow/actions/workflows/ci.yml/badge.svg)
[![Release](https://img.shields.io/github/v/release/grigoriev/alfred-seedbox-workflow)](https://github.com/grigoriev/alfred-seedbox-workflow/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=grigoriev_alfred-seedbox-workflow&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=grigoriev_alfred-seedbox-workflow)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=grigoriev_alfred-seedbox-workflow&metric=coverage)](https://sonarcloud.io/summary/new_code?id=grigoriev_alfred-seedbox-workflow)

The Mac front-end for the seedbox to Plex pipeline: a thin Alfred workflow that
drives the [sb-pull](https://github.com/grigoriev/sb-pull) agent on the server
over SSH and renders its JSON. All logic and secrets live in sb-pull; this
workflow holds only the SSH host.

The full design is in [SPEC.md](SPEC.md).

## Usage

Type `seedbox`:

- `seedbox` - list completed torrents on the seedbox, newest first,
  type-to-filter by name.
- `seedbox status` - transfer jobs (state, %, ETA).
- `seedbox >` - settings: set the SSH host, check for updates.

If the server is not reachable (you are off the LAN and VPN), the list shows a
single "beaver unreachable" hint instead of hanging.

## Requirements

- The [sb-pull](https://github.com/grigoriev/sb-pull) agent installed on the
  server, reachable over key-based SSH.
- Alfred 5 with the Powerpack.

## Development

```sh
make lint    # shellcheck
make test    # bats (ssh and open are mocked)
make build   # produce Seedbox.alfredworkflow
```

Bash 3.2 compatible. Every Script Filter renders with a single `jq` pass over
the agent's JSON.

## Status

Alpha. Phase P0 (list, status, settings, unreachable handling) is implemented;
the Send-to-Plex wizard (classify, TMDb, transfer) lands in later phases per
SPEC.md.
