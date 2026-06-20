#!/bin/bash
# Stato batteria per polybar, con click per il menu profili energetici.

BAT="/sys/class/power_supply/BAT0"
[ -d "$BAT" ] || exit 0

CAP="$(cat "$BAT/capacity" 2>/dev/null || echo 0)"
STATUS="$(cat "$BAT/status" 2>/dev/null || echo Unknown)"

if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
    ICON="🔋"
else
    ICON="🪫"
fi

if [ "$CAP" -le 20 ]; then
    COLOR="#ff3b3b"
elif [ "$CAP" -le 50 ]; then
    COLOR="#ffaa00"
else
    COLOR="#00ff41"
fi

echo "%{A1:/home/user/.local/bin/power-profile-toggle.sh:}%{F$COLOR}$ICON $CAP%%{F-}%{A}"
