#!/bin/bash
# Sospende il sistema dopo un periodo di inattivita' input, a meno che la CPU
# non sia occupata (load average sopra soglia).

IDLE_LIMIT_MS=1800000   # 30 minuti di inattivita'
CHECK_INTERVAL=60       # controlla ogni 60 secondi
LOAD_THRESHOLD=0.5      # non sospendere se il sistema sta lavorando

LOCKFILE="/tmp/auto-suspend.lock"
exec 200>"$LOCKFILE"
flock -n 200 || exit 0

log() {
    echo "[auto-suspend] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

# Verifica che xprintidle funzioni
if ! command -v xprintidle >/dev/null 2>&1; then
    log "xprintidle non trovato, esco"
    exit 1
fi

log "avviato: soglia inattivita' ${IDLE_LIMIT_MS}ms, check ogni ${CHECK_INTERVAL}s"

while true; do
    sleep "$CHECK_INTERVAL"

    # Tempo di inattivita' tastiera/mouse (ms)
    idle=$(xprintidle 2>/dev/null || echo 0)

    # Load average 1 minuto
    load=$(cut -d' ' -f1 /proc/loadavg)

    # Verifica se il carico e' sotto soglia
    load_ok=$(awk -v l="$load" -v t="$LOAD_THRESHOLD" 'BEGIN { print (l < t) ? 1 : 0 }')

    if [ "$idle" -ge "$IDLE_LIMIT_MS" ] && [ "$load_ok" -eq 1 ]; then
        log "inattivita' ${idle}ms, load ${load}: sospensione"
        systemctl suspend
    fi
done
