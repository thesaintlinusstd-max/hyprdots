#!/usr/bin/env bash
# mini CPU/RAM monitor: icon + percent only

# sample cpu over 0.7s
read_stat() {
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    echo "$((user + nice + system + irq + softirq + steal)) $((idle + iowait))"
}

read t1 i1 < <(read_stat)
sleep 0.7
read t2 i2 < <(read_stat)

d_total=$((t2 - t1))
d_idle=$((i2 - i1))

cpu=0
[ "$d_total" -gt 0 ] && cpu=$((100 * d_total / (d_total + d_idle)))
[ "$cpu" -lt 0 ] && cpu=0
[ "$cpu" -gt 100 ] && cpu=100

memtotal=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
memavail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
ram=$((100 * (memtotal - memavail) / memtotal))

text="<span size='small'>▦</span> ${cpu}% <span size='small' rise='-1'>▤</span> ${ram}%"
tooltip="CPU   ${cpu}%\nRAM   ${ram}%"

printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$tooltip"
