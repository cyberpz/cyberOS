#!/bin/bash
# Mostra la barra "cyber-hover" quando il cursore/penna è sopra la barra principale.
# La barra "cyber" resta sempre visibile e in primo piano.

SHOW_THRESHOLD=30      # pixel dal bordo superiore per mostrare la barra hover
HIDE_THRESHOLD=70      # pixel dal bordo superiore per nascondere la barra hover
HIDE_DELAY_CYCLES=3    # cicli di conferma prima di nascondere (~0.2s ciascuno)
SLEEP=0.2

HIDDEN=true
HIDE_COUNT=0

# Se xdotool non è disponibile, esci silenziosamente
which xdotool >/dev/null 2>&1 || exit 0

# Evita istanze multiple in caso di login/logout ripetuti
LOCKFILE="/tmp/polybar-hover-monitor.lock"
exec 200>"$LOCKFILE"
flock -n 200 || exit 0

hover_show() {
    for pid in $(pgrep -f "polybar cyber-hover$"); do
        polybar-msg -p "$pid" cmd show >/dev/null 2>&1
    done
    # Porta la barra hover sopra ogni altra finestra
    for wid in $(xdotool search --name "polybar-cyber-hover" 2>/dev/null); do
        xdotool windowraise "$wid" >/dev/null 2>&1 || true
    done
}

hover_hide() {
    for pid in $(pgrep -f "polybar cyber-hover$"); do
        polybar-msg -p "$pid" cmd hide >/dev/null 2>&1
    done
}

while true; do
    eval $(xdotool getmouselocation --shell 2>/dev/null)
    Y="${Y:-999}"

    if [ "$HIDDEN" = true ]; then
        # Barra hover nascosta: mostra se il cursore è sopra la barra principale
        if [ "$Y" -le "$SHOW_THRESHOLD" ]; then
            hover_show
            HIDDEN=false
            HIDE_COUNT=0
        fi
    else
        # Barra hover visibile: nascondi solo se il cursore esce dall'area totale
        if [ "$Y" -gt "$HIDE_THRESHOLD" ]; then
            HIDE_COUNT=$((HIDE_COUNT + 1))
            if [ "$HIDE_COUNT" -ge "$HIDE_DELAY_CYCLES" ]; then
                hover_hide
                HIDDEN=true
                HIDE_COUNT=0
            fi
        else
            HIDE_COUNT=0
        fi
    fi

    sleep "$SLEEP"
done
