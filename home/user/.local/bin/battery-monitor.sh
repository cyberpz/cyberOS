#!/bin/bash
# Monitora la batteria e attiva panik mode quando scende sotto il 20%.
# L'overlay panik si ripete ogni 5 minuti se la batteria rimane bassa e in scarica.

set -u

BAT="/sys/class/power_supply/BAT0"
LOW_THRESHOLD=20
CHECK_INTERVAL=30
PANIK_INTERVAL=300  # 5 minuti tra un overlay e l'altro
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/battery-monitor"
LAST_PANIK_FILE="$STATE_DIR/last-panik"

# Se non c'e' una batteria, non fare nulla
[ -d "$BAT" ] || exit 0

mkdir -p "$STATE_DIR"

log() {
    echo "[battery-monitor] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

show_panik() {
    # Overlay a schermo intero viola/verde
    rofi -e "BATTERIA!!!" -theme panik -monitor -1 2>/dev/null || true
    # Suona un beep se disponibile
    printf '\a' >/dev/tty0 2>/dev/null || true
}

last_panik_ts() {
    if [ -f "$LAST_PANIK_FILE" ]; then
        cat "$LAST_PANIK_FILE" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# Loop principale
while true; do
    sleep "$CHECK_INTERVAL"

    cap=$(cat "$BAT/capacity" 2>/dev/null || echo 100)
    status=$(cat "$BAT/status" 2>/dev/null || echo Unknown)

    if [ "$cap" -le "$LOW_THRESHOLD" ] && [ "$status" = "Discharging" ]; then
        log "batteria bassa: ${cap}% — attivo eco"
        /home/user/.local/bin/power-profile-apply.sh eco >/dev/null

        now=$(date +%s)
        last=$(last_panik_ts)

        if [ $((now - last)) -ge "$PANIK_INTERVAL" ]; then
            log "mostro overlay panik"
            show_panik
            echo "$now" > "$LAST_PANIK_FILE"
        fi
    fi
done
