#!/usr/bin/env bash

# اگر روی آیکون کلیک شد: تغییر وضعیت روشن/خاموش
if [ "$1" = "toggle" ]; then
    if systemctl --user is-active --quiet bpb; then
        systemctl --user stop bpb
    else
        systemctl --user start bpb
    fi
    exit 0
fi

# حالت نمایش در ویبار
if systemctl --user is-active --quiet bpb; then
    printf '{"text": "󰖂", "tooltip": "BPB Proxy: روشن (پورت 2080)", "class": "active"}\n'
else
    printf '{"text": "󰖃", "tooltip": "BPB Proxy: خاموش", "class": "inactive"}\n'
fi

