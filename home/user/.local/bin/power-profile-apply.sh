#!/bin/bash
# Applica un profilo energetico: performance, comfort, eco.
# Usato dal menu batteria e dal monitor batteria.

set -u

PROFILE="${1:-comfort}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/power-profile"
PICOM_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/picom/picom.conf"

mkdir -p "$STATE_DIR"

set_governor() {
    local gov="$1"
    if [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        echo "$gov" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
    else
        echo "$gov" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
    fi
}

set_epp() {
    local epp="$1"
    [ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ] || return 0
    if [ -w /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then
        echo "$epp" | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference >/dev/null
    else
        echo "$epp" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference >/dev/null
    fi
}

set_picom() {
    local on="$1"
    if [ "$on" = "1" ]; then
        if ! pgrep -x picom >/dev/null 2>&1; then
            (picom --config "$PICOM_CONF" &) 2>/dev/null
        fi
    else
        pkill -x picom 2>/dev/null || true
    fi
}

restart_auto_suspend() {
    local idle_ms="$1"
    systemctl --user stop auto-suspend.service 2>/dev/null || true
    systemd-run --user --unit=auto-suspend.service \
        --collect --property=Restart=always \
        /home/user/.local/bin/auto-suspend.sh "$idle_ms" >/dev/null
}

apply_profile() {
    local gov epp brightness picom_on idle_ms
    case "$PROFILE" in
        performance)
            gov=performance
            epp=performance
            brightness="100%"
            picom_on=1
            idle_ms=1800000
            ;;
        eco)
            gov=powersave
            epp=power
            brightness="50%"
            picom_on=0
            idle_ms=300000
            ;;
        comfort|*)
            gov=powersave
            epp=balance_performance
            brightness="75%"
            picom_on=1
            idle_ms=900000
            ;;
    esac

    set_governor "$gov"
    set_epp "$epp"
    brightnessctl set "$brightness" >/dev/null
    set_picom "$picom_on"
    restart_auto_suspend "$idle_ms"

    echo "$PROFILE" > "$STATE_DIR/current"
    dunstify -u low -t 2000 "Power Profile" "Profilo attivo: ${PROFILE^^}"
    echo "$PROFILE"
}

apply_profile
