#!/bin/bash
# mpris-exclusive.sh — نمایش آیکون‌های کوچک پلیرها و پلی انحصاری
# usage: mpris-exclusive.sh status  -> برای waybar (JSON)
#        mpris-exclusive.sh toggle -> کلیک: منوی انتخاب پلیر انحصاری
#        mpris-exclusive.sh exclusive <player> -> فقط اون پلیر پلی، بقیه پاز

ICON_BRAVE="🦁"
ICON_CHROMIUM="🌐"
ICON_FIREFOX=""
ICON_SPOTIFY=""
ICON_MPV=""
ICON_TELEGRAM=""
ICON_VLC=""
ICON_DEFAULT=""

get_icon() {
    case "$1" in
        brave*|chromium*|chrome*) echo "$ICON_BRAVE" ;;
        firefox*) echo "$ICON_FIREFOX" ;;
        spotify*) echo "$ICON_SPOTIFY" ;;
        mpv*) echo "$ICON_MPV" ;;
        Telegram*|telegram*) echo "$ICON_TELEGRAM" ;;
        vlc*) echo "$ICON_VLC" ;;
        *) echo "$ICON_DEFAULT" ;;
    esac
}

if [[ "$1" == "status" ]]; then
    players=$(playerctl -l 2>/dev/null)
    if [[ -z "$players" ]]; then
        echo '{"text": "", "tooltip": "No players", "class": "empty"}'
        exit 0
    fi
    text=""
    tooltip="Players (Playing only):"
    playing_count=0
    total_count=0
    for p in $players; do
        total_count=$((total_count+1))
        status=$(playerctl --player="$p" status 2>/dev/null)
        # فقط پلیرهایی که واقعا صدا دارن (Playing) رو حساب کن — شامل Brave، Firefox، Chrome، MPV، Telegram، Spotify و...
        if [[ "$status" == "Playing" ]]; then
            icon=$(get_icon "$p")
            text+="${icon} "
            tooltip+="\n$p: $status"
            playing_count=$((playing_count+1))
        fi
    done
    # فقط وقتی ۲ یا بیشتر همزمان Playing باشن نمایش بده — اگر فقط تلگرام پلی باشه اصلا ایکونی نیست
    if [[ $playing_count -lt 2 ]]; then
        echo '{"text": "", "tooltip": "single or no playing player", "class": "single"}'
        exit 0
    fi
    # escape برای JSON
    text=$(echo "$text" | xargs) # trim
    tooltip_esc=$(echo -e "$tooltip" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' | sed 's/^"//;s/"$//')
    # کلاس برای استایل
    echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip_esc\", \"class\": \"multi\"}"
    exit 0
fi

if [[ "$1" == "toggle" || "$1" == "toggle-force" ]]; then
    force="0"
    [[ "$1" == "toggle-force" ]] && force="1"
    players=$(playerctl -l 2>/dev/null)
    if [[ -z "$players" ]]; then
        notify-send "MPRIS" "No players found" 2>/dev/null || echo "No players"
        exit 0
    fi
    # فیلتر فقط پلیرهای قابل پخش (دارای title)
    playable_players=""
    for p in $players; do
        ti=$(playerctl --player="$p" metadata --format '{{title}}' 2>/dev/null)
        st=$(playerctl --player="$p" status 2>/dev/null)
        if [[ -n "$ti" && "$st" != "Stopped" ]]; then
            playable_players+="$p "
        fi
    done
    playable_players=$(echo "$playable_players" | xargs)
    count=$(echo "$playable_players" | wc -w)
    if [[ $count -le 1 && "$force" == "0" ]]; then
        # فقط یکی قابل پخشه -> play-pause ساده (در حالت عادی)
        if [[ -n "$playable_players" ]]; then
            playerctl --player="$(echo $playable_players)" play-pause
        else
            playerctl play-pause
        fi
        exit 0
    fi
    # اگر force بود و فقط یکی بود، باز هم لیست رو نشون بده (برای دابل‌کلیک)
    if [[ $count -eq 0 ]]; then
        notify-send "MPRIS" "No playable players" 2>/dev/null
        exit 0
    fi
    # لیست برای rofi/wofi — فقط قابل پخش‌ها
    list=""
    for p in $playable_players; do
        icon=$(get_icon "$p")
        status=$(playerctl --player="$p" status 2>/dev/null)
        title=$(playerctl --player="$p" metadata title 2>/dev/null | head -c 40)
        list+="$icon $p [$status] - $title\n"
    done
    # انتخابگر
    if command -v rofi >/dev/null 2>&1; then
        chosen=$(echo -e "$list" | rofi -dmenu -p "🎵 Exclusive play:" -i)
    elif command -v wofi >/dev/null 2>&1; then
        chosen=$(echo -e "$list" | wofi --dmenu -p "🎵 Exclusive play:")
    else
        # fallback: از اولین playing استفاده کن
        chosen=$(echo -e "$list" | head -n1)
    fi
    [[ -z "$chosen" ]] && exit 0
    # استخراج نام پلیر (دومین فیلد)
    # فرمت: "🦁 brave [Playing] - title"
    player=$(echo "$chosen" | awk '{print $2}')
    # exclusive: همه رو pause کن جز انتخاب شده
    for p in $players; do
        if [[ "$p" == "$player" ]]; then
            playerctl --player="$p" play 2>/dev/null
        else
            playerctl --player="$p" pause 2>/dev/null
        fi
    done
    exit 0
fi

# exclusive <player>
if [[ "$1" == "exclusive" && -n "$2" ]]; then
    players=$(playerctl -l 2>/dev/null)
    target="$2"
    for p in $players; do
        if [[ "$p" == "$target" ]]; then
            playerctl --player="$p" play
        else
            playerctl --player="$p" pause
        fi
    done
    exit 0
fi
