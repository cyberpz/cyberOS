#!/bin/bash
# domus-chat.sh — Apre/chiude la chat DOMUS in una piccola finestra Firefox senza UI.
# bind: $mod+Shift+d

URL="https://10.10.10.100"
PROFILE_DIR="$HOME/.mozilla/firefox/domus-chat"
PID_FILE="/tmp/domus-chat.pid"
WIDTH=520
HEIGHT=720

# Crea il profilo se non esiste
if [ ! -d "$PROFILE_DIR" ]; then
    mkdir -p "$PROFILE_DIR/chrome"
fi

# Se esiste un processo precedente, uccidilo (toggle chiudi)
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null || kill -9 "$OLD_PID" 2>/dev/null || true
        rm -f "$PID_FILE"
        # Aspetta che la finestra sparisca
        for i in $(seq 1 20); do
            if ! kill -0 "$OLD_PID" 2>/dev/null; then
                break
            fi
            sleep 0.1
        done
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Avvia Firefox con profilo dedicato
firefox -profile "$PROFILE_DIR" --new-instance --no-remote "$URL" >/dev/null 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

# Attendi che la finestra appaia
WIN=""
for i in $(seq 1 50); do
    # Cerca una finestra Firefox appartenente al processo
    for candidate in $(xdotool search --onlyvisible --class "firefox" 2>/dev/null); do
        # Controlla se la finestra ha caricato DOMUS o è una nuova finestra del profilo
        title=$(xdotool getwindowname "$candidate" 2>/dev/null || true)
        if [[ "$title" == *"DOMUS"* ]] || [[ "$title" == *"Mozilla Firefox"* ]]; then
            WIN="$candidate"
            break 2
        fi
    done
    sleep 0.2
done

if [ -z "$WIN" ]; then
    notify-send "DOMUS Chat" "Impossibile trovare la finestra DOMUS" 2>/dev/null || true
    exit 1
fi

# Ottieni ID i3 della finestra
I3_ID=$(printf "0x%x" "$WIN")

# Configura la finestra: flottante, piccola, centrata, bordo verde
i3-msg "[id=\"$I3_ID\"] floating enable, resize set $WIDTH $HEIGHT, move position center, sticky enable, border pixel 2" >/dev/null 2>&1 || true

# Attiva e porta in primo piano
xdotool windowactivate "$WIN" 2>/dev/null || true
xdotool windowraise "$WIN" 2>/dev/null || true

exit 0
