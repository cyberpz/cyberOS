#!/bin/bash
# polybar-wireguard.sh — Toggle WireGuard PzBench e mostra stato in polybar

IFACE="PzBench"
SCRIPT="$0"

toggle() {
    if ip link show "$IFACE" >/dev/null 2>&1; then
        sudo wg-quick down "$IFACE"
    else
        sudo wg-quick up "$IFACE"
    fi
}

show() {
    if ip link show "$IFACE" >/dev/null 2>&1; then
        # 🔒 connesso, verde Matrix
        echo "%{A1:$SCRIPT toggle:}%{F#00ff41}🔒%{F-}%{A}"
    else
        # 🔓 disconnesso, grigio
        echo "%{A1:$SCRIPT toggle:}%{F#6b6b8a}🔓%{F-}%{A}"
    fi
}

case "${1:-show}" in
    toggle) toggle ;;
    *) show ;;
esac
