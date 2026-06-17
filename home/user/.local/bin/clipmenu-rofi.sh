#!/bin/bash
# Apre clipmenu con rofi (tema cyber, piccolo box, history infinita).
# Delete su una riga la rimuove dalla history e rimane aperto per cancellazioni multiple.

export CM_DIR="${XDG_RUNTIME_DIR:-/tmp}"
major_version=6
cache_dir="$CM_DIR/clipmenu.$major_version.$USER"
cache_file="$cache_dir/line_cache"

if ! [[ -f $cache_file ]]; then
    exit 0
fi

# Lista le clip in ordine cronologico inverso, rimuovendo duplicati
list_clips() {
    LC_ALL=C sort -rnk 1 < "$cache_file" | cut -d' ' -f2- | awk '!seen[$0]++'
}

# Rofi con tema cyber, adattato per il box clipboard (piccolo, in alto a sinistra)
rofi_cmd=(
    rofi
    -dmenu
    -p "Clipboard"
    -no-show-icons
    -kb-remove-char-forward ""
    -kb-custom-1 "Delete"
    -lines 12
    -width 35
    -location 1
    -yoffset 28
    -theme-str 'window { width: 380px; height: 360px; border-radius: 0; }'
    -theme-str 'mainbox { padding: 4px; }'
    -theme-str 'listview { lines: 12; }'
    -theme-str 'element { padding: 4px 6px; }'
    -theme-str 'element-icon { size: 0em; }'
)

while true; do
    chosen=$(list_clips | "${rofi_cmd[@]}")
    exit_code=$?

    # Esc o chiusura senza selezione: esci
    [[ -z "${chosen:-}" ]] && exit 0

    if [[ $exit_code -eq 10 ]]; then
        # Delete: elimina la clip selezionata e riapri il menu.
        # Escapa i metacaratteri sed BRE (. * [ \ ^ $) per un match esatto.
        escaped=$(printf '%s' "$chosen" | sed 's/[.*\^$]/\\&/g')
        clipdel -d "$escaped" >/dev/null 2>&1 || true
    else
        # Copia la clip selezionata negli appunti (stesso metodo di clipmenu: xsel).
        file="$cache_dir/$(cksum <<< "$chosen")"
        if [[ -f "$file" ]]; then
            for selection in clipboard primary; do
                xsel --logfile /dev/null -i --"$selection" < "$file" || true
            done
        fi
        # Incolla automaticamente nella finestra precedente (Ctrl+Shift+V).
        # Usato per terminali/Kimi Code CLI che usano Shift+Ctrl+V per incollare.
        sleep 0.15
        xdotool key --clearmodifiers ctrl+shift+v || true
        exit 0
    fi
done
