# Render "GET /torrents" into Alfred items, filtered by the query. Enter drills
# into the Send-to-Plex wizard for that torrent.
#
# Args: --arg q, --arg icon_multi, --arg icon_file

def human($b):
  if $b >= 1073741824 then ((($b / 1073741824) * 10 | floor) / 10 | tostring) + " GB"
  elif $b >= 1048576 then (($b / 1048576) | floor | tostring) + " MB"
  else (($b / 1024) | floor | tostring) + " KB" end;

def matches($q; $name):
  ($q | ascii_downcase | split(" ") | map(select(length > 0))) as $w
  | ($name | ascii_downcase) as $n
  | ($w | length) == 0 or all($w[]; . as $t | $n | contains($t));

(.items // [])
| map(select(matches($q; .name)))
| map({
    uid: .hash,
    title: .name,
    subtitle: (human(.size) + "   ·   " + (if .is_multi then "folder" else "file" end) + "   ·   ↵ send to Plex"),
    arg: ("wizard " + .hash),
    autocomplete: ("@" + .hash + " "),
    valid: true,
    icon: { path: (if .is_multi then $icon_multi else $icon_file end) }
  })
