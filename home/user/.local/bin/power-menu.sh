#!/bin/bash
# power-menu.sh — Menu rofi per spegnimento/riavvio/sospensione/blocco

choices="Sospendi\nBlocca\nRiavvia\nSpegni\nAnnulla"
chosen=$(echo -e "$choices" | rofi -dmenu -p "Power" -no-show-icons -lines 5 -width 15 -location 0)

case "$chosen" in
    Sospendi)
        /home/user/.local/bin/standby.sh
        ;;
    Blocca)
        i3lock -n -c 000000
        ;;
    Riavvia)
        systemctl reboot
        ;;
    Spegni)
        systemctl poweroff
        ;;
    *)
        exit 0
        ;;
esac
