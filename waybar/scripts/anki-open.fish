#!/usr/bin/env fish
# Anki-card popup: selected text -> Duck.ai with Anki prompt (no service bar)
set SCRIPTS ~/.config/waybar/scripts
set WORD (string trim "$WORD" 2>/dev/null)
set CONTENT_PROFILE $HOME/.cache/chromium-anki
set W 560
set H 620

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

function place_center -a profile w h outfile fb
    # center on focused monitor
    set MW 1920; set MH 1080
    set GEO (hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | "\(.width) \(.height)"' | head -n 1)
    if test -n "$GEO"
        set PARTS (string split ' ' -- $GEO)
        test (count $PARTS) -ge 2; and set MW $PARTS[1]; and set MH $PARTS[2]
    end
    set X (math "floor(($MW - $w) / 2)")
    set Y (math "floor(($MH - $h) / 2)")
    test "$X" -lt 0; and set X 0
    test "$Y" -lt 0; and set Y 0
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
    hyprctl dispatch "hl.dsp.window.move({ x = $X, y = $Y, relative = false, window = '$WA' })" >/dev/null
    hyprctl dispatch "hl.dsp.window.resize({ x = $w, y = $h, relative = false, window = '$WA' })" >/dev/null
    set PINNED (hyprctl clients -j | jq -r --arg a "$ADDR" '.[] | select(.address == $a) | .pinned')
    test "$PINNED" != true; and hyprctl dispatch "hl.dsp.window.pin({ action = 'toggle', window = '$WA' })" >/dev/null
end

rm -f /tmp/anki-content.addr
wait_death $CONTENT_PROFILE

set FULL "$WORD"
# Generic Anki prompt. To personalize (e.g. add your own field of study)
# create ~/.config/hyprdots/prompts/anki-prompt.txt — it overrides the default
# and is never committed (gitignored). See prompts/anki-prompt.txt.example.
set DEFAULT_PROMPT "تو یک استاد دانشگاه و متخصص ساخت فلش‌کارت آنکی به زبان فارسی هستی. متن انتخاب‌شده در انتهای این پیام می‌آید (ممکن است انگلیسی یا فارسی باشد). فقط همین دو کار را به همین ترتیب انجام بده و هیچ کار دیگری نکن: 1) ترجمه: اول یک ترجمه دقیق، روان و علمی از کل متن به فارسی بنویس. 2) کارت آنکی: بعد بر اساس همان متن فقط یک کارت آنکی عالی به زبان فارسی بساز (یک سؤال کوتاه و دقیق + یک جواب کامل ولی خلاصه، مناسب حفظ کردن). اگر اصطلاحی واقعا قابل ترجمه به فارسی نیست آن را به انگلیسی نگه دار. برای اطمینان از درستی علمی حتما از جست‌وجوی وب استفاده کن و بهترین و دقیق‌ترین کارت ممکن را پیشنهاد بده. کل خروجی فارسی و کاملا راست‌چین و منظم باشد"
set PROMPT_FILE $HOME/.config/hyprdots/prompts/anki-prompt.txt
set PROMPT ""
if test -f "$PROMPT_FILE"
    set PROMPT (cat "$PROMPT_FILE" 2>/dev/null | string collect | string trim)
end
test -z "$PROMPT"; and set PROMPT $DEFAULT_PROMPT
set PQ (python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$PROMPT متن: $FULL")

set URL "https://duck.ai/?q=$PQ"

set UENC (string escape --style=url -- "$URL")
chromium --app="file://$SCRIPTS/anki-load.html#u=$UENC" \
    --user-data-dir=$CONTENT_PROFILE --window-size=560,620 \
    --no-first-run --no-default-browser-check --password-store=basic \
    --hide-crash-bubble --disable-session-crashed-bubble >/dev/null 2>&1 &
disown
place_center $CONTENT_PROFILE $W $H /tmp/anki-content.addr anki-content
