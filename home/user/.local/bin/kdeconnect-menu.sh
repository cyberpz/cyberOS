#!/bin/bash
# kdeconnect-menu.sh — Menu rapido KDE Connect

if ! pgrep -x kdeconnectd >/dev/null 2>&1; then
    /usr/bin/kdeconnectd &
    sleep 2
fi

devices=$(kdeconnect-cli -l --id-only 2>/dev/null)
if [ -z "$devices" ]; then
    rofi -e "Nessun dispositivo KDE Connect trovato.\nInstalla KDE Connect sul telefono e assicurati che sia sulla stessa rete." -width 35
    exit 0
fi

# Prendi il primo dispositivo
id=$(echo "$devices" | head -1)
name=$(kdeconnect-cli -l 2>/dev/null | grep "$id" | sed 's/.*: \(.*\) (\(.*\)).*/\1/')

choices="Apri KDE Connect\nInvia ping\nTrova dispositivo\nCondividi clipboard\nInvia file...\nEsci"
chosen=$(echo -e "$choices" | rofi -dmenu -p "$name" -no-show-icons -lines 6 -width 25 -location 0)

case "$chosen" in
    "Apri KDE Connect")
        kdeconnect-app >/dev/null 2>&1 &
        ;;
    "Invia ping")
        kdeconnect-cli -d "$id" --ping-msg "Ciao da cyberOS" >/dev/null 2>&1
        ;;
    "Trova dispositivo")
        kdeconnect-cli -d "$id" --ring >/dev/null 2>&1
        ;;
    "Condividi clipboard")
        clip=$(xclip -o -selection clipboard 2>/dev/null || xsel -b 2>/dev/null || echo "")
        if [ -n "$clip" ]; then
            echo "$clip" | kdeconnect-cli -d "$id" --send-clipboard >/dev/null 2>&1
        fi
        ;;
    "Invia file...")
        file=$(zenity --file-selection 2>/dev/null || rofi -dmenu -p "Percorso file" -width 40)
        if [ -n "$file" ] && [ -f "$file" ]; then
            kdeconnect-cli -d "$id" --share "$file" >/dev/null 2>&1
        fi
        ;;
    *)
        exit 0
        ;;
esac
