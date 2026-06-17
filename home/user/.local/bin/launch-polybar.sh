#!/bin/bash
# Lancia polybar "cyber" (sempre visibile) e "cyber-hover" (nascosta di default)

LOGFILE="/tmp/polybar-launch.log"
: > "$LOGFILE"

killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 0.1; done

PIDS=""

launch_bar() {
    local MONITOR=$1
    export MONITOR
    polybar --reload cyber >>"$LOGFILE" 2>&1 &
    PIDS="$PIDS $!"
    polybar --reload cyber-hover >>"$LOGFILE" 2>&1 &
    PIDS="$PIDS $!"
}

if type "xrandr" >/dev/null 2>&1; then
    for m in $(polybar --list-monitors | cut -d: -f1); do
        launch_bar "$m"
    done
else
    launch_bar ""
fi

# La barra hover parte nascosta; viene mostrata dal monitor di hover
sleep 1
for pid in $(pgrep -f "polybar --reload cyber-hover"); do
    polybar-msg -p "$pid" cmd hide >/dev/null 2>&1 || true
done

# Forza la barra hover sopra ogni finestra (sovraimpressione)
sleep 0.5
for wid in $(xdotool search --name "polybar-cyber-hover" 2>/dev/null); do
    xprop -id "$wid" -f _NET_WM_STATE 32a -set _NET_WM_STATE _NET_WM_STATE_ABOVE 2>/dev/null || true
done

# Aspetta che i processi polybar terminino (necessario per systemd/tmux)
wait $PIDs
