# Render "sb-pull list" output into Alfred items, filtered by the query. Items
# are non-actionable for now; the Send-to-Plex wizard arrives in a later phase.
#
# Args: --arg q, --arg icon_multi, --arg icon_file

def human($b):
  if $b >= 1073741824 then ((($b / 1073741824) * 10 | floor) / 10 | tostring) + " GB"
  elif $b >= 1048576 then (($b / 1048576) | floor | tostring) + " MB"
  else (($b / 1024) | floor | tostring) + " KB" end;

def matches($q; $name):
  ($q | ascii_downcase | split(" ") | map(select(length > 0))) as $w
  | ($w | length) == 0
  or ($name | ascii_downcase) as $n | all($w[]; . as $t | $n | contains($t));

(.items // [])
| map(select(matches($q; .name)))
| map({
    uid: .hash,
    title: .name,
    subtitle: (human(.size) + "   ·   " + (if .is_multi then "folder" else "file" end)),
    valid: false,
    icon: { path: (if .is_multi then $icon_multi else $icon_file end) }
  })
