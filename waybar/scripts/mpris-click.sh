#!/bin/bash
# mpris-click.sh — تک‌کلیک = play/pause، دابل‌کلیک = لیست انتخاب پلیر انحصاری
# waybar هر کلیک رو جدا صدا می‌زنه، پس با فایل timestamp دابل‌کلیک رو تشخیص می‌دیم

CLICK_FILE="/tmp/mpris-click-time"
LOCK_FILE="/tmp/mpris-click-lock"
NOW=$(date +%s%N)

mkdir -p /tmp

# اگر فایل قبلی وجود داشت و اختلاف کمتر از 400ms بود → دابل‌کلیک
if [[ -f "$CLICK_FILE" ]]; then
    LAST=$(cat "$CLICK_FILE" 2>/dev/null)
    if [[ -n "$LAST" ]]; then
        DIFF=$(( (NOW - LAST) / 1000000 ))
        if [[ $DIFF -lt 300 && $DIFF -ge 0 ]]; then
            # دابل‌کلیک شناسایی شد → لیست انتخاب پلیر انحصاری
            rm -f "$CLICK_FILE" "$LOCK_FILE"
            exec ~/.config/waybar/scripts/mpris-exclusive.sh toggle-force
            exit 0
        fi
    fi
fi

# تک‌کلیک احتمالی — timestamp رو ذخیره کن و کمی صبر کن ببین کلیک دوم میاد یا نه
echo "$NOW" > "$CLICK_FILE"

# 350ms منتظر دابل‌کلیک بمون (در پس‌زمینه اجرا میشه تا waybar هنگ نکنه)
(
    sleep 0.2
    # اگر بعد از 350ms هنوز همین timestamp داخل فایل بود → یعنی دابل‌کلیک نیومده → تک‌کلیک = play-pause
    if [[ -f "$CLICK_FILE" ]]; then
        STORED=$(cat "$CLICK_FILE" 2>/dev/null)
        if [[ "$STORED" == "$NOW" ]]; then
            rm -f "$CLICK_FILE"
            playerctl play-pause
        fi
    fi
) &

exit 0
