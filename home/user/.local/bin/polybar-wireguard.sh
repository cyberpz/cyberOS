#!/bin/bash
# Polybar WireGuard module per DebianPz
WG_IF="PzBench"

if [ "$1" = "--toggle" ]; then
    if ip link show "$WG_IF" >/dev/null 2>&1; then
        sudo wg-quick down "$WG_IF" >/dev/null 2>&1
    else
        sudo wg-quick up "$WG_IF" >/dev/null 2>&1
    fi
    exit 0
fi

if ip link show "$WG_IF" >/dev/null 2>&1; then
    echo "%{F#00ff41}🛡️%{F-}"
else
    echo "%{F#6b6b8a}🔓%{F-}"
fi
