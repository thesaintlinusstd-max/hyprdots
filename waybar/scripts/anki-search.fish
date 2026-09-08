#!/usr/bin/env fish
# Alt+A: selected text -> Duck.ai Anki card (centered float, no service bar)
set SCRIPTS ~/.config/waybar/scripts
set ANKI_PROFILE $HOME/.cache/chromium-anki
set WORD (wl-paste --primary 2>/dev/null; or wl-paste 2>/dev/null)
if test -n "$WORD"
    set WORD (echo "$WORD" | string replace -a -r '[ \t]+' ' ' | string trim | string sub --length 4000)
end

function wait_death -a profile
    pkill -f "user-data-dir=$profile" 2>/dev/null
    for i in (seq 1 20)
        pgrep -f "user-data-dir=$profile" >/dev/null 2>&1; or return 0
        sleep 0.1
    end
    pkill -9 -f "user-data-dir=$profile" 2>/dev/null
    for i in (seq 1 10)
        pgrep -f "user-data-dir=$profile" >/dev/null 2>&1; or return 0
        sleep 0.1
    end
end

# toggle without word: close anki popup
if test -z "$WORD"
    if pgrep -f "user-data-dir=$ANKI_PROFILE" >/dev/null 2>&1
        wait_death $ANKI_PROFILE
        rm -f /tmp/anki-content.addr
    end
    exit 0
end

# close previous anki window
if test -f /tmp/anki-content.addr
    hyprctl dispatch "hl.dsp.window.close({ window = 'address:'(cat /tmp/anki-content.addr) })" >/dev/null 2>&1
    rm -f /tmp/anki-content.addr
end
for addr in (hyprctl clients -j | jq -r '.[] | select((.title // "") | test("^anki-content")) | .address')
    hyprctl dispatch "hl.dsp.window.close({ window = 'address:$addr' })" >/dev/null 2>&1
end
wait_death $ANKI_PROFILE

# close dict windows too so Alt+W / Alt+A don't overlap
for f in /tmp/dict-content.addr /tmp/dict-bar.addr
    if test -f $f
        hyprctl dispatch "hl.dsp.window.close({ window = 'address:'(cat $f) })" >/dev/null 2>&1
        rm -f $f
    end
end
for addr in (hyprctl clients -j | jq -r '.[] | select((.title // "") | test("^(dict-bar|dict-content)")) | .address')
    hyprctl dispatch "hl.dsp.window.close({ window = 'address:$addr' })" >/dev/null 2>&1
end
wait_death $HOME/.cache/chromium-dict-content
wait_death $HOME/.cache/chromium-dict-bar

env WORD="$WORD" fish $SCRIPTS/anki-open.fish
