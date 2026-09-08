#!/bin/bash
# mpris-status.sh — نمایش درست آیکون پخش/توقف و ترانکیت اسم + تولتیپ هاور برای انتخاب پلیر
# وقتی ۲+ پلیر قابل پخش دارن (Playing/Paused با title)، هاور تولتیپ پایین باز میشه با لیست کوچیک
# کلیک: اگر ۲+ پلیر فعاله -> منوی exclusive، وگرنه play-pause

get_icon() {
    case "$1" in
        brave*|chromium*|chrome*) echo "🦁" ;;
        firefox*) echo "" ;;
        spotify*) echo "" ;;
        mpv*) echo "" ;;
        Telegram*|telegram*) echo "" ;;
        vlc*) echo "" ;;
        *) echo "" ;;
    esac
}

# پلیر اصلی (آخرین فعال)
status=$(playerctl status 2>/dev/null)
player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)
title=$(playerctl metadata --format '{{title}}' 2>/dev/null)
artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null)

# اگر هیچی پلی نیست، خالی برگردون (waybar مخفی میکنه)
if [[ -z "$status" ]]; then
    echo '{"text": "", "tooltip": "No media", "class": "empty"}'
    exit 0
fi

# آیکون وضعیت: Nerd Font icons با ارتفاع یکسان
# nf-fa-pause =  nf-fa-play =
if [[ "$status" == "Playing" ]]; then
    status_icon=""
    cls="playing"
else
    status_icon=""
    cls="paused"
fi

player_icon=$(get_icon "$player")

# ساخت متن با ترانکیت ۱۵ کاراکتر
# فرمت: "  🦁 Title" یا "  🦁 Title"
if [[ -n "$artist" ]]; then
    full="$title - $artist"
else
    full="$title"
fi
# ترانکیت: اگر بیشتر از ۱۵ کاراکتر شد، ببر
if [[ ${#full} -gt 15 ]]; then
    full="${full:0:15}"
fi

if [[ "$status" == "Playing" ]]; then
    text="$status_icon $player_icon $full"
else
    text="$status_icon $player_icon $full"
fi

# تولتیپ: لیست همه پلیرهایی که چیزی قابل پخش دارن (Playing/Paused با title)
players=$(playerctl -l 2>/dev/null)
tooltip=""
playable_count=0
for p in $players; do
    p_status=$(playerctl --player="$p" status 2>/dev/null)
    p_title=$(playerctl --player="$p" metadata --format '{{title}}' 2>/dev/null)
    # فقط پلیرهایی که title دارن و Stopped نیستن
    if [[ -n "$p_title" && "$p_status" != "Stopped" ]]; then
        icon=$(get_icon "$p")
        # اگر Playing باشه آیکون ، وگرنه
        if [[ "$p_status" == "Playing" ]]; then
            s=""
        else
            s=""
        fi
        tooltip+="$icon $p $s $p_title\n"
        playable_count=$((playable_count+1))
    fi
done

if [[ $playable_count -ge 2 ]]; then
    tooltip="🎵 چند پلیر فعال (هاور: لیست، کلیک: انتخاب انحصاری):\n$tooltip"
    cls="multi"
    # تریم newline آخر
    tooltip=$(echo -e "$tooltip" | sed 's/\n$//')
else
    if [[ -n "$artist" ]]; then
        tooltip="$player: $title - $artist [$status]"
    else
        tooltip="$player: $title [$status]"
    fi
fi

# escape JSON
text_esc=$(printf '%s' "$text" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])')
tooltip_esc=$(printf '%s' "$tooltip" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])')

echo "{\"text\": \"$text_esc\", \"tooltip\": \"$tooltip_esc\", \"class\": \"$cls\"}"
