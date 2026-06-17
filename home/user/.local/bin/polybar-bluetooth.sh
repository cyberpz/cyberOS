#!/bin/bash
# polybar-bluetooth.sh — Mostra stato Bluetooth e toggla power al click

if [ "$1" = "toggle" ]; then
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        bluetoothctl power off >/dev/null 2>&1
    else
        bluetoothctl power on >/dev/null 2>&1
    fi
    exit 0
fi

if ! command -v bluetoothctl >/dev/null 2>&1; then
    echo "%{F#6b6b8a}BT%{F-}"
    exit 0
fi

if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    # Verifica se c'è almeno un dispositivo connesso
    if bluetoothctl devices Connected 2>/dev/null | grep -qE '^Device'; then
        echo "%{A1:$0 toggle:}%{F#00ff41}🎧%{F-}%{A}"
    else
        echo "%{A1:$0 toggle:}%{F#00ff41}🔵%{F-}%{A}"
    fi
else
    echo "%{A1:$0 toggle:}%{F#6b6b8a}⚪%{F-}%{A}"
fi
