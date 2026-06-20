#!/bin/bash
# Rinomina i workspace di i3 con il titolo della finestra attiva in ogni workspace.
# Se un workspace e' vuoto, usa il nome di default.

set -u

DEFAULT_NAMES=(
    "term"   # 1
    "web"    # 2
    "code"   # 3
    "files"  # 4
    "git"    # 5
    "chat"   # 6
    "media"  # 7
    "sys"    # 8
    "vm"     # 9
    "music"  # 10
)

MAX_TITLE_LEN=20

# Evita istanze multiple
LOCKFILE="/tmp/i3-dynamic-workspace-names.lock"
exec 200>"$LOCKFILE"
flock -n 200 || exit 0

get_default_name() {
    local num="$1"
    local idx=$((num - 1))
    if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#DEFAULT_NAMES[@]}" ]; then
        echo "${DEFAULT_NAMES[$idx]}"
    else
        echo "$num"
    fi
}

truncate_title() {
    local title="$1"
    if [ "${#title}" -gt "$MAX_TITLE_LEN" ]; then
        echo "${title:0:$MAX_TITLE_LEN}…"
    else
        echo "$title"
    fi
}

update_names() {
    local tree workspaces
    tree=$(i3-msg -t get_tree 2>/dev/null) || return
    workspaces=$(i3-msg -t get_workspaces 2>/dev/null) || return

    echo "$workspaces" | jq -c '.[]' | while read -r ws; do
        local num old_name new_title new_name
        num=$(echo "$ws" | jq -r '.num')
        old_name=$(echo "$ws" | jq -r '.name')

        # Trova il titolo della finestra focalizzata nel workspace, oppure la prima finestra
        new_title=$(echo "$tree" | jq -r --argjson num "$num" '
            (.. | objects | select(.type == "workspace" and .num == $num)) as $ws_node |
            ($ws_node | .. | objects | select(.focused == true and .window != null) | .name) //
            ($ws_node | .. | objects | select(.window != null) | .name)
        ' | head -n1)

        if [ -z "$new_title" ] || [ "$new_title" = "null" ]; then
            new_title=$(get_default_name "$num")
        fi

        new_title=$(truncate_title "$new_title")
        new_name="$num:$new_title"

        if [ "$old_name" != "$new_name" ]; then
            i3-msg rename workspace "\"$old_name\"" to "\"$new_name\"" >/dev/null 2>&1 || true
        fi
    done
}

# Aggiornamento iniziale
update_names

# Ascolta eventi di finestre e workspace tramite FIFO per poter pulire i processi figli
FIFO="/tmp/i3-dynamic-workspace-names.fifo"
rm -f "$FIFO"
mkfifo "$FIFO" 2>/dev/null || true

cleanup() {
    exec 3<&- 2>/dev/null || true
    rm -f "$FIFO"
    kill 0 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT TERM INT

i3-msg -t subscribe -m '["window","workspace"]' > "$FIFO" &
SUBPID=$!

# Apre la FIFO in lettura/scrittura e la tiene aperta per evitare EOF e perdite di eventi
exec 3<> "$FIFO"

while read -r _event <&3; do
    update_names
done

wait $SUBPID 2>/dev/null || true
