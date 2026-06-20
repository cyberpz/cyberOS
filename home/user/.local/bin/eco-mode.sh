#!/bin/bash
# Toggle modalità eco per cyberOS.
# Riduce consumi e rumore limitando CPU, luminosità, compositor e aumentando
# l'aggressività dell'auto-suspend.

set -u

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/eco-mode"
STATE_FILE="$STATE_DIR/state"
DEFAULT_IDLE_MS=1800000
ECO_IDLE_MS=300000
PICOM_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/picom/picom.conf"

usage() {
    echo "Uso: $(basename "$0") {on|off|toggle|status}" >&2
    exit 1
}

ensure_state_dir() {
    mkdir -p "$STATE_DIR"
}

is_on() {
    [ -f "$STATE_FILE" ]
}

get_governor() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown"
}

get_epp() {
    cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "N/A"
}

set_governor() {
    local gov="$1"
    if [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        echo "$gov" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
    else
        echo "sudo richiesto per impostare il governor" >&2
        echo "$gov" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
    fi
}

set_epp() {
    local epp="$1"
    [ "$epp" = "N/A" ] && return 0
    if [ -w /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then
        echo "$epp" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference >/dev/null
    else
        echo "$epp" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference >/dev/null
    fi
}

restart_auto_suspend() {
    local idle_ms="$1"
    systemctl --user stop auto-suspend.service 2>/dev/null || true
    systemd-run --user --unit=auto-suspend.service \
        --collect --property=Restart=always \
        /home/user/.local/bin/auto-suspend.sh "$idle_ms" >/dev/null
}

eco_on() {
    ensure_state_dir

    # Salva stato corrente
    get_governor > "$STATE_DIR/governor"
    get_epp > "$STATE_DIR/epp"
    brightnessctl get > "$STATE_DIR/brightness"
    if pgrep -x picom >/dev/null 2>&1; then
        echo 1 > "$STATE_DIR/picom"
    else
        echo 0 > "$STATE_DIR/picom"
    fi

    # Applica profilo eco
    set_governor powersave
    set_epp power
    brightnessctl set 50% >/dev/null
    pkill -x picom 2>/dev/null || true
    restart_auto_suspend "$ECO_IDLE_MS"

    touch "$STATE_FILE"
    echo "Modalità eco ON (CPU powersave, luminosità 50%, auto-suspend 5min, picom off)"
}

eco_off() {
    if [ ! -d "$STATE_DIR" ]; then
        echo "Nessuno stato salvato, impossibile ripristinare" >&2
        exit 1
    fi

    # Fallback ragionevoli se qualche file di stato manca
    local gov epp brightness picom_on
    gov="$(cat "$STATE_DIR/governor" 2>/dev/null || echo performance)"
    epp="$(cat "$STATE_DIR/epp" 2>/dev/null || echo default)"
    brightness="$(cat "$STATE_DIR/brightness" 2>/dev/null || brightnessctl max 2>/dev/null || echo 6818)"
    picom_on="$(cat "$STATE_DIR/picom" 2>/dev/null || echo 1)"

    # Ripristina stato
    set_governor "$gov"
    set_epp "$epp"
    brightnessctl set "$brightness" >/dev/null
    if [ "$picom_on" = "1" ]; then
        if ! pgrep -x picom >/dev/null 2>&1; then
            (picom --config "$PICOM_CONF" &) 2>/dev/null
        fi
    fi
    restart_auto_suspend "$DEFAULT_IDLE_MS"

    rm -f "$STATE_FILE"
    echo "Modalità eco OFF (stato ripristinato, auto-suspend 30min)"
}

case "${1:-toggle}" in
    on)  eco_on ;;
    off) eco_off ;;
    toggle)
        if is_on; then
            eco_off
        else
            eco_on
        fi
        ;;
    status)
        if is_on; then
            echo "Modalità eco: ON"
            echo "  governor: $(get_governor)"
            echo "  EPP: $(get_epp)"
            echo "  brightness: $(brightnessctl get)"
            echo "  picom: $(pgrep -x picom >/dev/null && echo running || echo stopped)"
            echo "  auto-suspend: $(systemctl --user is-active auto-suspend.service 2>/dev/null || echo inactive)"
        else
            echo "Modalità eco: OFF"
        fi
        ;;
    *) usage ;;
esac
