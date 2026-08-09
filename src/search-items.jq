# Render "GET /search" TMDb candidates into Alfred items, filtered by the query.
# Enter starts the transfer with that candidate's kind and canonical name.
#
# Args: --arg q, --arg hash, --arg icon_movie, --arg icon_tv

def canonical:
  .original_title + (if (.year // "") != "" then " (" + .year + ")" else "" end);

def kind_label($k):
  {movie: "Movie", cartoon: "Cartoon", series: "Series", cartoon_series: "Cartoon series"}[$k] // $k;

def matches($q; $name):
  ($q | ascii_downcase | split(" ") | map(select(length > 0))) as $w
  | ($name | ascii_downcase) as $n
  | ($w | length) == 0 or all($w[]; . as $t | $n | contains($t));

(.candidates // [])
| map(select(matches($q; .original_title + " " + (.title // ""))))
| map(
    canonical as $name
    | {
        uid: (.tmdb_id | tostring),
        title: $name,
        subtitle: (kind_label(.kind) + (if (.overview // "") != "" then "   ·   " + .overview else "" end)),
        arg: ("start " + $hash + " " + .kind + " " + $name),
        valid: true,
        icon: { path: (if (.media == "tv") then $icon_tv else $icon_movie end) }
      }
  )
