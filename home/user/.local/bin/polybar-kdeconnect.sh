#!/bin/bash
# polybar-kdeconnect.sh — Indicatore stato KDE Connect

if [ "$1" = "open" ]; then
    kdeconnect-app >/dev/null 2>&1 &
    exit 0
fi

if ! pgrep -x kdeconnectd >/dev/null 2>&1; then
    echo "%{F#6b6b8a}📵%{F-}"
    exit 0
fi

connected=$(kdeconnect-cli -l --id-only 2>/dev/null | head -1)
if [ -n "$connected" ]; then
    # C'è almeno un dispositivo accoppiato/raggiungibile
    name=$(kdeconnect-cli -l 2>/dev/null | grep -v '^0 devices' | head -1 | sed 's/.*: \(.*\) (\(.*\)).*/\1/')
    echo "%{A1:$0 open:}%{F#00ff41}📲%{F-}%{A}"
else
    echo "%{A1:$0 open:}%{F#6b6b8a}📱%{F-}%{A}"
fi
