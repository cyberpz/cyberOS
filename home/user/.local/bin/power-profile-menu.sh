#!/bin/bash
# Menu rofi per scegliere il profilo energetico.
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

CHOICE=$(printf "Performance\nComfort\nEco" | /usr/bin/rofi -dmenu -p "Profilo" -theme power-profile)

[ -z "$CHOICE" ] && exit 0
exec /home/user/.local/bin/power-profile-apply.sh "$CHOICE"
