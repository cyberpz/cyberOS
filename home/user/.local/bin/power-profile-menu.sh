#!/bin/bash
# Menu rofi per scegliere il profilo energetico.

set -u

CHOICE=$(printf "Performance\nComfort\nEco" | rofi -dmenu -p "Profilo" -theme power-profile)

[ -z "$CHOICE" ] && exit 0
exec /home/user/.local/bin/power-profile-apply.sh "$CHOICE"
