#!/usr/bin/env bash
set -euo pipefail

VENV="/tmp/jdatetime-venv"
PYTHON="${VENV}/bin/python3"

if [[ ! -x "$PYTHON" ]]; then
    printf '{"text": "%s", "tooltip": "%s"}\n' "$(date '+%H:%M')" "$(date '+%A %d %B %Y')"
    exit 0
fi

"$PYTHON" -c "
import json, jdatetime
from datetime import datetime

now = datetime.now()
g = now.date()
j = jdatetime.date.fromgregorian(date=g)

wd_names = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه\u200cشنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه']
pm = ['', 'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند']
gm_fa = ['', 'ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن', 'جولای', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر']
en_days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

hour = f'{now.hour:02d}'
minute = f'{now.minute:02d}'

text = f'{hour}:{minute}  <span color=\"#ffcc66\" size=\"smaller\">{j.day}</span>'
tooltip = f'{en_days[g.weekday()]} | {wd_names[j.weekday()]} {j.day} {pm[j.month]} {j.year}'

print(json.dumps({'text': text, 'tooltip': tooltip}, ensure_ascii=False))
"