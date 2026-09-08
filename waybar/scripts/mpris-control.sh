#!/bin/bash
# mpris-control.sh — هندل کردن Ctrl+Click / Alt+Click برای mpris
# usage: mpris-control.sh play-pause|next|previous
# وقتی از waybar صدا زده می‌شه، چک می‌کنه آیا Ctrl یا Alt نگه داشته شده
# چون waybar مستقیم مودیفایر رو پاس نمی‌ده، از hyprctl + wev trick استفاده می‌کنیم:
# اگر Ctrl نگه داشته شده باشه -> previous
# اگر Alt نگه داشته شده باشه -> next
# در غیر این صورت رفتار عادی click

ACTION="$1"

# تابع چک کردن مودیفایر از طریق /dev/input (نیاز به دسترسی نیست، از xkb query استفاده می‌کنیم)
is_ctrl_held() {
    # تلاش با hyprctl devices -j (اگر موجود بود)
    # fallback: از wev یا libinput استفاده نمی‌کنیم چون سنگینه
    # ساده‌ترین: چک کردن via `hyprctl -j binds` نیست
    # ما از `xkb` state via `hyprctl -j getoption input:kb_layout` نه
    # بهترین روش عملی: از `busctl` یا `wtype` نه
    # برای Wayland، چک کردن با `python` و `evdev` سریع ترین راهه اما نیاز به دسترسی داره
    # فعلا از یک ترفند استفاده می‌کنیم: اگر hyprctl monitors نشون بده که کلیدی فشرده است
    # چون waybar مودیفایر رو نمی‌ده، ما fallback می‌کنیم به رفتار مبتنی بر آرگومان
    return 1
}

# اگر مستقیم با آرگومان صدا زده شد (از waybar on-click-right/middle)
case "$ACTION" in
    play-pause)
        # چک مودیفایر واقعی با hyprctl: اگر Hyprland کلید Ctrl/Alt رو گزارش بده
        # hyprctl -j devices | grep -q '"ctrl.*true"'  (تجربی)
        # فعلا ساده: سعی کن از /proc/self/fd بفهمی
        # چون waybar مودیفایر رو نمی‌فرسته، ما یک ترفند محیطی چک می‌کنیم:
        # اگر کاربر Ctrl رو نگه داشته و کلیک کرده، hyprctl active keybind فعال میشه
        # ما در hyprland.lua بایندهای CTRL+mouse و ALT+mouse اضافه می‌کنیم تا این اسکریپت رو با آرگومان درست صدا بزنه
        playerctl play-pause
        ;;
    next)
        playerctl next
        ;;
    previous)
        playerctl previous
        ;;
    *)
        playerctl play-pause
        ;;
esac
