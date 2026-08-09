# alfred-seedbox-workflow — Specification (Draft v1)

The **Mac front-end** for the seedbox to Plex pipeline: a thin Alfred workflow
that drives the `sb-ctrl` backend on Ubuntu `beaver.h.g7v.io` over its **REST
API** and renders the JSON. All logic, metadata, and secrets live in `sb-ctrl`
(see `sb-ctrl/SPEC.md`); this workflow holds only the API URL and a token.

Status: implemented (list, wizard, status, settings).

---

## 1. Role & architecture

- **bash 3.2**, following the grigoriev Alfred conventions: `workflow_handler.sh`
  (Script Filter JSON), the `>` settings menu, the shared updater, bats/kcov
  tests, SonarCloud. See the `alfred-workflow` skill.
- Every Script Filter calls the `sb-ctrl` REST API with `curl` and renders the
  result with `jq`. No rTorrent/TMDb/naming logic here — that is the API
  contract in `sb-ctrl/SPEC.md`.
- **Only config on the Mac:** the API base URL (default
  `https://beaver.h.g7v.io`) and a bearer token, stored in the workflow data dir.
  Server settings (roots, perms, keys) live in `sb-ctrl` and are read via
  `GET /config`.

---

## 2. Keyword & modes

Keyword `seedbox`:

- `seedbox` — list completed torrents (`GET /torrents`), newest first,
  type-to-filter.
- `seedbox status` — transfer jobs + progress (`GET /jobs`), per-job retry.
- `seedbox >` — settings: set the API URL, set the token, check for updates.

---

## 3. HTTP invocation & reachability

- Pattern: `curl -sS -m 8 --connect-timeout 4 -H "Authorization: Bearer <token>"
  "<base><path>"`, capturing the body and the HTTP status.
- **Unreachable** (off LAN and VPN): the fast `--connect-timeout` fails → show
  one clear "beaver unreachable" item, not a hang.
- **API errors** (non-2xx): show `sb-ctrl error (<code>)` with the `detail` from
  the JSON body.
- JSON parsed with a single `jq` pass into Script Filter items (perf rule).

---

## 4. The Send-to-Plex wizard

A sequence of Script Filter states, each calling an API endpoint and
autocompleting into the next:

- `seedbox` → torrents (`GET /torrents`); Enter → `@<hash>`.
- `@<hash>` → TMDb candidates (`GET /search`, rendered with the detected kind
  and canonical `Name (Year)`).
- Enter on a candidate → `POST /jobs` (collision overwrite), a macOS
  notification, then a jump to `seedbox status`.

A collision preview step (`POST /plan`) can be added later.

---

## 5. Status view

- `GET /jobs` → items per job: name, state, `pct` / rate / ETA. Auto-refresh via
  Script Filter rerun while any job is active.
- Actions: retry a failed job (`POST /jobs/{id}/retry`), dismiss.
- macOS notification on job completion.

---

## 6. Settings (`seedbox >`)

- **Set API URL** / **Set API token** — edit the local config files.
- Shared **Check for updates** + autoupdate toggle (from the updater bundle).

---

## 7. Conventions & build

- Repo standards (CI, SonarCloud, Renovate, rulesets, release) per the
  `grigoriev-opensource` skill; bash/macOS layer per `alfred-workflow`.
- bats tests mock `curl` (feed canned API JSON) so the UI is testable without a
  live server.

---

The server contract this workflow calls is defined in **`sb-ctrl/SPEC.md`**.
