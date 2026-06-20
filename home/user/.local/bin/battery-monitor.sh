#!/bin/bash
# Monitora la batteria e attiva panik mode quando scende sotto il 20%.

set -u

BAT="/sys/class/power_supply/BAT0"
LOW_THRESHOLD=20
CHECK_INTERVAL=30
PANIK_LOCK="/tmp/battery-panik.lock"

# Se non c'e' una batteria, non fare nulla
[ -d "$BAT" ] || exit 0

# Crea directory per lo stato del monitor
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/battery-monitor"

log() {
    echo "[battery-monitor] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

show_panik() {
    # Mostra l'overlay panik in loop finche' la batteria non risale o si ricarica.
    # Usa un lock per evitare piu' istanze sovrapposte.
    exec 200>"$PANIK_LOCK"
    if ! flock -n 200; then
        return 0
    fi

    (
        while true; do
            [ -d "$BAT" ] || break
            cap=$(cat "$BAT/capacity" 2>/dev/null || echo 100)
            status=$(cat "$BAT/status" 2>/dev/null || echo Unknown)

            # Esci dal loop se la batteria e' carica o sopra soglia
            if [ "$cap" -gt "$LOW_THRESHOLD" ] || [ "$status" != "Discharging" ]; then
                break
            fi

            # Suona un beep se disponibile
            printf '\a' >/dev/tty0 2>/dev/null || true

            # Overlay a schermo intero viola/verde
            rofi -e "BATTERIA!!!" -theme panik -monitor -1 2>/dev/null || true

            sleep 5
        done
    ) &
}

# Loop principale
while true; do
    sleep "$CHECK_INTERVAL"

    cap=$(cat "$BAT/capacity" 2>/dev/null || echo 100)
    status=$(cat "$BAT/status" 2>/dev/null || echo Unknown)

    if [ "$cap" -le "$LOW_THRESHOLD" ] && [ "$status" = "Discharging" ]; then
        log "batteria bassa: ${cap}% — attivo eco + panik mode"
        /home/user/.local/bin/power-profile-apply.sh eco >/dev/null
        show_panik
    fi
done
