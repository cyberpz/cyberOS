#!/bin/bash
# Apre il menu per scegliere il profilo energetico.
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
touch /tmp/power-profile-click-test
exec /home/user/.local/bin/power-profile-menu.sh
