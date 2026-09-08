#!/usr/bin/env fish
set service $argv[1]
set SCRIPTS ~/.config/waybar/scripts
set WORD (string trim "$WORD" 2>/dev/null)
set CONTENT_PROFILE $HOME/.cache/chromium-dict-content

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

rm -f /tmp/dict-content.addr
wait_death $CONTENT_PROFILE

set FULL "$WORD"
set CAMWORD (string sub --length 60 -- "$WORD")
set HYPHEN (string replace -a ' ' '-' "$CAMWORD")
# Generic translator prompt. To personalize (e.g. add your own field of study)
# create ~/.config/hyprdots/prompts/dict-prompt.txt — it overrides the default
# and is never committed (gitignored). See prompts/dict-prompt.txt.example.
set DEFAULT_PROMPT "تو یک مترجم علمی دقیق و یک استاد آموزش زبان هستی. متن انگلیسی انتهای این پیام را به فارسی جواب بده، کاملا راست‌چین و منظم با این ترتیب: 1) ترجمه کامل: یک ترجمه دقیق، روان، علمی و خوب از کل متن. 2) کالوکیشن‌ها رو هم بنویس: مهم‌ترین هم‌نشینی‌های کلمه کلیدی با معنی فارسی و یک مثال کوتاه. 3) کاربرد در جمله: 2-3 جمله انگلیسی با ترجمه فارسی. 4) ریشه‌شناسی و آموزش زبانی خلاصه: ریشه، مترادف‌ها و متضادها. اگر متن به یک حوزه تخصصی (علمی یا فنی) مربوط است، یک توضیح تخصصی مختصر هم اضافه کن. خلاصه بگو"
set PROMPT_FILE $HOME/.config/hyprdots/prompts/dict-prompt.txt
set PROMPT ""
if test -f "$PROMPT_FILE"
    set PROMPT (cat "$PROMPT_FILE" 2>/dev/null | string collect | string trim)
end
test -z "$PROMPT"; and set PROMPT $DEFAULT_PROMPT
set PQ (python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$PROMPT متن: $FULL")

set URL ""; set PROXY ""
switch $service
    case duck
        set URL "https://duck.ai/?q=$PQ"
    case cambridge
        set URL "https://dictionary.cambridge.org/dictionary/english/$HYPHEN"
    case google
        set BPB ""
        set PID (pgrep -f "sing-box run -c" | head -n 1)
        if test -n "$PID"
            set CWD (readlink /proc/$PID/cwd)
            set CFG (tr "\0" "\n" < /proc/$PID/cmdline | grep -A 1 '^-c$' | tail -n 1)
            if string match -q '/*' -- "$CFG"; set BPB "$CFG"
            else if test -n "$CFG"; set BPB "$CWD/$CFG"; end
        end
        if test -z "$BPB"
            for p in $HOME/bpb.json $HOME/.config/sing-box/bpb.json $HOME/sing-box/bpb.json
                if test -e "$p"; set BPB "$p"; break; end
            end
        end
        if test -z "$PID"; and test -n "$BPB"
            nohup sing-box run -c "$BPB" >/dev/null 2>&1 &
            disown; sleep 1
        end
        set PORT ""; set TYPE ""
        if test -n "$BPB"
            set PORT (jq -r '[.inbounds[]? | select(.type=="mixed" or .type=="http" or .type=="socks") | .listen_port] | .[0] // empty' "$BPB" 2>/dev/null)
            set TYPE (jq -r '[.inbounds[]? | select(.type=="mixed" or .type=="http" or .type=="socks") | .type] | .[0] // "mixed"' "$BPB" 2>/dev/null)
        end
        test -n "$PORT"; or set PORT 2080
        if test "$TYPE" = socks; set PROXY "--proxy-server=socks5://127.0.0.1:$PORT"
        else; set PROXY "--proxy-server=127.0.0.1:$PORT"; end
        set URL "https://www.google.com/search?q=$PQ"
end

set UENC (string escape --style=url -- "$URL")
set CMD chromium --app="file://$SCRIPTS/dict-load.html#u=$UENC" \
    --user-data-dir=$CONTENT_PROFILE --window-size=460,520 \
    --no-first-run --no-default-browser-check --password-store=basic \
    --hide-crash-bubble --disable-session-crashed-bubble
if test -n "$PROXY"; set CMD $CMD $PROXY; end
$CMD >/dev/null 2>&1 &
disown
place $CONTENT_PROFILE 453 144 460 520 /tmp/dict-content.addr dict-content
