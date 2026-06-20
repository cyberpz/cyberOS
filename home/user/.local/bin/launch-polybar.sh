#!/bin/bash
# Lancia polybar "cyber" (sempre visibile)

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
}

if type "xrandr" >/dev/null 2>&1; then
    for m in $(polybar --list-monitors | cut -d: -f1); do
        launch_bar "$m"
    done
else
    launch_bar ""
fi

# Aspetta che i processi polybar terminino (necessario per systemd/tmux)
wait $PIDS
