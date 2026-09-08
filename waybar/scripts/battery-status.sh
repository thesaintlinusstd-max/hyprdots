#!/usr/bin/env bash

# پیدا کردن مسیر باتری روی سیستم
BAT_DIR=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1)

if [ -z "$BAT_DIR" ]; then
    echo '{"text": "N/A"}'
    exit 0
fi

capacity=$(cat "$BAT_DIR/capacity" 2>/dev/null || echo "0")
status=$(cat "$BAT_DIR/status" 2>/dev/null || echo "Discharging")
profile=$(powerprofilesctl get 2>/dev/null || echo "balanced")

# تعیین آیکون بر اساس وضعیت
if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
    icon="🔌" # علامت دوشاخ هنگام شارژ
elif [ "$profile" = "performance" ]; then
    icon="⚡" # علامت رعد و برق برای قدرت کامل
else
    # آیکون‌های معمولی باتری بر اساس درصد
    if [ "$capacity" -gt 80 ]; then icon=""
    elif [ "$capacity" -gt 60 ]; then icon=""
    elif [ "$capacity" -gt 40 ]; then icon=""
    elif [ "$capacity" -gt 20 ]; then icon=""
    else icon=""
    fi
fi

# خروجی به فرمت JSON برای وای‌بار
if [ "$profile" = "performance" ]; then
    class="performance"
else
    class="balanced"
fi

echo "{\"text\": \"${capacity}% ${icon}\", \"tooltip\": \"حالت فعلی: ${profile}\", \"class\": \"${class}\"}"
