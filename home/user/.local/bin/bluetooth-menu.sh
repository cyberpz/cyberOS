#!/bin/bash
# bluetooth-menu.sh — Menu rofi per gestire Bluetooth

while true; do
    status=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
    if [ "$status" = "yes" ]; then
        power_choice="Spegni Bluetooth"
        scan_choice="Scansiona dispositivi"
    else
        power_choice="Accendi Bluetooth"
        scan_choice=""
    fi

    choices="$power_choice\nDispositivi connessi\n$scan_choice\nEsci"
    chosen=$(echo -e "$choices" | grep -v '^$' | rofi -dmenu -p "Bluetooth" -no-show-icons -lines 6 -width 25 -location 0)

    case "$chosen" in
        "Accendi Bluetooth")
            bluetoothctl power on
            ;;
        "Spegni Bluetooth")
            bluetoothctl power off
            ;;
        "Scansiona dispositivi")
            bluetoothctl scan on &
            sleep 5
            devices=$(bluetoothctl devices 2>/dev/null | awk '{print $3}' | head -10)
            if [ -n "$devices" ]; then
                dev=$(echo -e "$devices\nAnnulla" | rofi -dmenu -p "Connetti" -no-show-icons -lines 10 -width 30 -location 0)
                if [ "$dev" != "Annulla" ] && [ -n "$dev" ]; then
                    mac=$(bluetoothctl devices 2>/dev/null | grep "$dev" | awk '{print $2}')
                    bluetoothctl connect "$mac"
                fi
            else
                rofi -e "Nessun dispositivo trovato" -width 20
            fi
            bluetoothctl scan off >/dev/null 2>&1
            ;;
        "Dispositivi connessi")
            connected=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $3}')
            if [ -n "$connected" ]; then
                echo -e "$connected" | rofi -dmenu -p "Connessi" -no-show-icons -lines 5 -width 30 -location 0
            else
                rofi -e "Nessun dispositivo connesso" -width 25
            fi
            ;;
        *)
            exit 0
            ;;
    esac
done
