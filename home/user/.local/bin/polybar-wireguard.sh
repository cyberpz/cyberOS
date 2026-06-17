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
        # 🔒 connesso
        echo "%{A1:$SCRIPT toggle:}🔒%{A}"
    else
        # 🔓 disconnesso
        echo "%{A1:$SCRIPT toggle:}🔓%{A}"
    fi
}

case "${1:-show}" in
    toggle) toggle ;;
    *) show ;;
esac
