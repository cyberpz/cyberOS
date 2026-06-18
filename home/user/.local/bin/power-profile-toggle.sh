#!/bin/bash
# power-profile-toggle.sh — Switcha tra profilo performance e powersave

CURRENT=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

if [ "$CURRENT" = "performance" ]; then
    NEW="powersave"
else
    NEW="performance"
fi

for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$cpu" ] && echo "$NEW" | sudo tee "$cpu" >/dev/null 2>&1
done

# Notifica
if command -v dunstify >/dev/null 2>&1; then
    dunstify -u low -t 2000 "Power Profile" "Switched to: $NEW"
fi

echo "$NEW"
