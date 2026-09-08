#!/usr/bin/env fish
if hyprctl clients -j | jq -e '.[] | select((.class // "") | test("^chromium-dict"))' >/dev/null
    echo '{"text": "📖", "tooltip": "Dictionary (Open)", "class": "active"}'
else
    echo '{"text": "📖", "tooltip": "Dictionary", "class": "inactive"}'
end
