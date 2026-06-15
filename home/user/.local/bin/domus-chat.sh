#!/bin/bash
# domus-chat.sh — Apre/chiude la chat DOMUS in una finestra Firefox flottante.
# bind: $mod+Shift+d

URL="https://10.10.10.100"
TITLE_PATTERN="DOMUS // SYS"
WIDTH=800
HEIGHT=650

# Cerca finestre DOMUS esistenti
WINDOWS=$(xdotool search --onlyvisible --name "$TITLE_PATTERN" 2>/dev/null)

if [ -n "$WINDOWS" ]; then
    # Chiudi tutte le finestre DOMUS trovate
    for win in $WINDOWS; do
        xdotool windowclose "$win" 2>/dev/null || true
    done
    exit 0
fi

# Apri Firefox in una nuova finestra privata
firefox --new-window --private-window "$URL" &

# Attendi che la finestra appaia
for i in $(seq 1 30); do
    WIN=$(xdotool search --onlyvisible --name "$TITLE_PATTERN" 2>/dev/null | head -1)
    if [ -n "$WIN" ]; then
        break
    fi
    sleep 0.2
done

if [ -z "$WIN" ]; then
    notify-send "DOMUS Chat" "Impossibile aprire la finestra DOMUS" 2>/dev/null || true
    exit 1
fi

# Ottieni ID i3 della finestra
I3_ID=$(printf "0x%x" "$WIN")

# Configura la finestra: flottante, dimensioni fisse, centrata, sempre in primo piano
i3-msg "[id=\"$I3_ID\"] floating enable, resize set $WIDTH $HEIGHT, move position center, sticky enable, border pixel 2" >/dev/null 2>&1 || true

# Attiva e porta in primo piano
xdotool windowactivate "$WIN" 2>/dev/null || true
xdotool windowraise "$WIN" 2>/dev/null || true

exit 0
