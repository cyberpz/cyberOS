#!/bin/bash
# Imposta la luminosita al massimo su tutti i dispositivi backlight
for dev in /sys/class/backlight/*; do
    [ -d "$dev" ] || continue
    max=$(cat "$dev/max_brightness" 2>/dev/null)
    [ -n "$max" ] && echo "$max" > "$dev/brightness" 2>/dev/null
done
# Fallback con brightnessctl se disponibile
command -v brightnessctl >/dev/null 2>&1 && brightnessctl set 100% >/dev/null 2>&1
