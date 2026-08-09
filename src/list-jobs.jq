# Render "sb-pull status" jobs into Alfred items.
# Args: --arg icon

(.jobs // [])
| map({
    uid: .id,
    title: (.name // .id),
    subtitle: ((.state // "?")
      + (if .pct != null then "   ·   " + (.pct | tostring) + "%" else "" end)
      + (if (.eta // "") != "" then "   ·   ETA " + .eta else "" end)
      + (if (.error // "") != "" then "   ·   " + .error else "" end)),
    valid: false,
    icon: { path: $icon }
  })
