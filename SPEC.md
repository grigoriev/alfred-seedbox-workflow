# alfred-seedbox-workflow — Specification (Draft v1)

The **Mac front-end** for the seedbox → Plex pipeline: a thin Alfred workflow
that drives the `sb-pull` agent on Ubuntu `beaver.h.g7v.io` over SSH and renders
its JSON. All logic, metadata, and secrets live in **sb-pull** (see
`sb-pull/SPEC.md`); this workflow holds none.

Status: plan only, no implementation.

---

## 1. Role & architecture

- **bash 3.2**, following the grigoriev Alfred conventions: `workflow_handler.sh`
  (Script Filter JSON), the `>` settings menu, the shared updater, bats/kcov
  tests, SonarCloud. See the `alfred-workflow` skill.
- Every Script Filter runs `ssh <ssh_host> sb-pull <cmd> --json ...`, parses the
  result with `jq`, and renders items. No rTorrent/TMDb/naming logic here — that
  is the `sb-pull` CLI contract (`sb-pull/SPEC.md` §4).
- **Only config on the Mac:** `ssh_host` (default `beaver.h.g7v.io`). Server
  settings (roots, perms, keys) are edited via `sb-pull config` over SSH.

---

## 2. Keyword & modes

Keyword `sb` (or `seedbox`):

- `sb` — list completed torrents (`sb-pull list`), newest first, type-to-filter.
- `sb status` — active transfer jobs + whatbox in-progress downloads
  (`sb-pull status`), auto-refreshing; per-job **retry** / open log.
- `sb >` — settings & updates: edit server config (`sb-pull config edit` over
  SSH), set `ssh_host`, check for updates, autoupdate toggle.

---

## 3. The "Send to Plex" wizard

A sequence of Script Filter states; each renders `sb-pull` output and
autocompletes into the next state. State (chosen hash / files / kind / tmdb_id)
is carried in the query and/or the workflow data dir.

1. **Pick** a completed torrent (`sb-pull list`).
2. *(folder)* optionally drill in → select a file subset (`sb-pull files <hash>`).
3. **Category** guess → confirm / override (4 options; guess from
   `sb-pull search --kind auto`).
4. **TMDb match** — `sb-pull search` candidates → pick one, or enter title+year.
5. *(TV)* review the episode mapping (from `sb-pull plan`) → confirm / fix.
6. **Preview** — `sb-pull plan` returns final paths, perms, and collisions. On a
   collision, ask **overwrite / skip / cancel**.
7. **Enter** → `sb-pull run` → shows the new job id; hands off to `sb status`.

---

## 4. SSH invocation & reachability

- Pattern: `ssh -o ConnectTimeout=4 <ssh_host> sb-pull <cmd> --json <args>`.
- **Unreachable** (no LAN/VPN): the fast `ConnectTimeout` fails → show
  "beaver unreachable — connect to VPN or LAN", not a hang. Every mode degrades
  to this single clear item.
- JSON parsed with a single `jq` pass into Script Filter items (per the perf rule).
- Args with spaces/quotes passed safely (printf %q / here-strings), never
  interpolated raw into the remote command.

---

## 5. Status view

- `sb-pull status` → items per job: name, state (queued/active/done/failed),
  `pct` / rate / ETA. Auto-refresh via Script Filter rerun while any job is active.
- Also lists whatbox in-progress torrents for visibility.
- Actions: **retry** a failed job (`sb-pull retry`), open its log, dismiss.
- **macOS notification** on job completion (success/failure) — the status view (or
  a light background check) detects the state flip and posts a native notification.

---

## 6. Settings (`sb >`)

- **Edit server config** — opens `sb-pull config edit` on beaver over SSH
  (roots, perms, TMDb key, rTorrent creds live there, not on the Mac).
- **SSH host** — set/override `ssh_host`.
- Shared **Check for updates** + autoupdate toggle (from the updater bundle).

---

## 7. Conventions & build

- Repo standards (CI, SonarCloud, Renovate, rulesets, release) per the
  `grigoriev-opensource` skill; bash/macOS layer per `alfred-workflow`.
- bats tests mock `ssh` (feed canned `sb-pull` JSON) so the UI is testable
  without a live server. Target the usual coverage/0-issues bar.

## 8. Build phasing (tracks sb-pull)

- **P0** `sb` list + `sb status` against `sb-pull list`/`status`; unreachable UX.
- **P1** wizard steps 1–2 + `run` of a whole title (no naming yet).
- **P2** category + TMDb pick + preview (`search`/`plan`) for movies.
- **P3** TV mapping UI.
- **P4** file-subset selection, notifications, retry actions, `>` polish.

---

The server contract this workflow calls is defined in **`sb-pull/SPEC.md`**.
