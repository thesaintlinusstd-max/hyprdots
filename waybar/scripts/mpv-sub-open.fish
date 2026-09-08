#!/usr/bin/env fish
# mpv subtitle -> EXACT same popup as Alt+W (Duck.ai content + bar, same prompt).
# WORD comes from /tmp/mpv-sub.txt (written synchronously by mpv lua, no clipboard race).
set SCRIPTS ~/.config/waybar/scripts
set BAR_PROFILE $HOME/.cache/chromium-dict-bar
set WORD ""
if test -f /tmp/mpv-sub.txt
    set WORD (cat /tmp/mpv-sub.txt 2>/dev/null | string replace -a -r '[ \t]+' ' ' | string trim | string sub --length 4000)
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

function place -a profile x y w h outfile fb
    set ADDR ""
    for i in (seq 1 60)
        set PIDS (pgrep -f "user-data-dir=$profile" | string join ' ')
        if test -n "$PIDS"
            set ADDR (hyprctl clients -j | jq -r --arg ps "$PIDS" '($ps|split(" ")) as $q | .[] | select(.pid as $p | $q | index(($p|tostring))) | .address' | head -n 1)
        end
        if test -z "$ADDR"; and test -n "$fb"
            set ADDR (hyprctl clients -j | jq -r --arg t "$fb" '.[] | select(.title == $t) | .address' | head -n 1)
        end
        test -n "$ADDR"; and break
        sleep 0.1
    end
    test -z "$ADDR"; and return 1
    echo "$ADDR" > $outfile
    set WA "address:$ADDR"
    for attempt in (seq 1 3)
        set FL (hyprctl clients -j | jq -r --arg a "$ADDR" '.[] | select(.address == $a) | .floating')
        test "$FL" = true; and break
        hyprctl dispatch "hl.dsp.window.float({ action = 'toggle', window = '$WA' })" >/dev/null
        sleep 0.2
    end
    hyprctl dispatch "hl.dsp.window.move({ x = $x, y = $y, relative = false, window = '$WA' })" >/dev/null
    hyprctl dispatch "hl.dsp.window.resize({ x = $w, y = $h, relative = false, window = '$WA' })" >/dev/null
    set PINNED (hyprctl clients -j | jq -r --arg a "$ADDR" '.[] | select(.address == $a) | .pinned')
    test "$PINNED" != true; and hyprctl dispatch "hl.dsp.window.pin({ action = 'toggle', window = '$WA' })" >/dev/null
end

# toggle بدون متن
if test -z "$WORD"
    if pgrep -f "user-data-dir=$HOME/.cache/chromium-dict-" >/dev/null 2>&1
        wait_death $HOME/.cache/chromium-dict-content
        wait_death $BAR_PROFILE
        rm -f /tmp/dict-content.addr /tmp/dict-bar.addr
    end
    exit 0
end

# بستن قبلی‌ها
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
wait_death $BAR_PROFILE

# سرور لوکال
if not curl -s -m 1 http://127.0.0.1:7634/ping >/dev/null 2>&1
    nohup python3 $SCRIPTS/dict-server.py >/dev/null 2>&1 &
    disown; sleep 0.3
end

# محتوا — پیش‌فرض Duck.ai (دقیقا همان پرامپت Alt+W در dict-open.fish)
env WORD="$WORD" fish $SCRIPTS/dict-open.fish duck

# نوار
set WENC (string escape --style=url -- "$WORD")
chromium --app="file://$SCRIPTS/dict-bar.html#w=$WENC" \
    --user-data-dir=$BAR_PROFILE --window-size=460,34 \
    --no-first-run --no-default-browser-check --password-store=basic \
    --hide-crash-bubble --disable-session-crashed-bubble >/dev/null 2>&1 &
disown
place $BAR_PROFILE 453 104 460 34 /tmp/dict-bar.addr dict-bar
