#!/bin/bash
# harness-domus.sh — Pannello di controllo Domus via rofi
# bind: $mod+Shift+d

DOMUS="domus"
DOMUS_IP="10.10.10.100"
AGENTMEMORY_PROXY="/root/.local/bin/am-mcp-proxy.py"
CYBEROS_REPO="$HOME/cyberOS"

# Rofi cyberpunk theme
rofi_cmd=(
    rofi -dmenu -p "HarnessDomus" -no-show-icons
    -lines 10 -width 40 -location 1 -yoffset 28
    -theme-str 'window { width: 480px; height: 360px; border-radius: 0; border: 2px; border-color: #00ff41; background-color: #000000; }'
    -theme-str 'mainbox { padding: 4px; background-color: #000000; }'
    -theme-str 'listview { lines: 10; background-color: #000000; }'
    -theme-str 'element { padding: 6px 8px; background-color: #000000; text-color: #00ff41; }'
    -theme-str 'element selected.normal { background-color: #00ff41; text-color: #000000; }'
    -theme-str 'element-icon { size: 0em; }'
    -theme-str 'prompt { text-color: #00ff41; font: "Terminus Bold 13"; }'
    -theme-str 'inputbar { background-color: #000000; text-color: #00ff41; }'
    -theme-str 'entry { background-color: #000000; text-color: #00ff41; }'
)

notify() {
    dunstify -a "HarnessDomus" -i network-server "$1" "$2" 2>/dev/null || notify-send "$1" "$2" 2>/dev/null || true
}

ssh_domus() {
    ssh -T -o ConnectTimeout=5 "$DOMUS" "$@"
}

# Menu principale
main_menu() {
    cat <<EOF
🟢  Status Domus
💾  AgentMemory: salva nota
🔍  AgentMemory: ricerca
🖥️  Esegui comando su Domus
📊  Statistiche sistema
🔄  Backup cyberOS su Domus
📁  Monta filesystem Domus
🌐  Apri IP Domus nel browser
EOF
}

# Status
status_domus() {
    if ssh_domus 'echo ok' >/dev/null 2>&1; then
        uptime=$(ssh_domus 'uptime -p' 2>/dev/null || echo "N/A")
        ip=$(ssh_domus 'hostname -I' 2>/dev/null || echo "N/A")
        notify "Domus online" "Uptime: $uptime\nIP: $ip"
    else
        notify "Domus offline" "Impossibile connettersi a $DOMUS_IP"
    fi
}

# AgentMemory: salva
am_save() {
    content=$(rofi -dmenu -p "Nota da salvare in agentmemory" -lines 0 -width 60 \
        -theme-str 'window { width: 600px; border: 2px; border-color: #00ff41; background-color: #000000; }' \
        -theme-str 'prompt { text-color: #00ff41; }' \
        -theme-str 'entry { text-color: #00ff41; }')
    [ -z "$content" ] && return
    
    topic=$(rofi -dmenu -p "Topic/argomento" -lines 0 -width 40 \
        -theme-str 'window { width: 400px; border: 2px; border-color: #00ff41; background-color: #000000; }' \
        -theme-str 'prompt { text-color: #00ff41; }' \
        -theme-str 'entry { text-color: #00ff41; }' \
        <<< "debianpz-cyberpunk-workbench")
    [ -z "$topic" ] && topic="debianpz-cyberpunk-workbench"
    
    notify "AgentMemory" "Salvataggio in corso..."
    
    python3 - <<PY | ssh_domus "python3 $AGENTMEMORY_PROXY"
import json, sys
req = {
    "jsonrpc": "2.0", "id": 1,
    "method": "initialize",
    "params": {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "harness-domus", "version": "0.1.0"}
    }
}
print(json.dumps(req))
req2 = {
    "jsonrpc": "2.0", "id": 2,
    "method": "tools/call",
    "params": {
        "name": "memory_save",
        "arguments": {
            "project": "$topic",
            "type": "fact",
            "content": $(python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< """$content"""),
            "concepts": "DebianPz, domus, harness"
        }
    }
}
print(json.dumps(req2))
PY
    
    if [ $? -eq 0 ]; then
        notify "AgentMemory" "Nota salvata su Domus"
    else
        notify "AgentMemory" "Errore nel salvataggio"
    fi
}

# AgentMemory: ricerca
am_search() {
    query=$(rofi -dmenu -p "Cerca in agentmemory" -lines 0 -width 50 \
        -theme-str 'window { width: 500px; border: 2px; border-color: #00ff41; background-color: #000000; }' \
        -theme-str 'prompt { text-color: #00ff41; }' \
        -theme-str 'entry { text-color: #00ff41; }')
    [ -z "$query" ] && return
    
    notify "AgentMemory" "Ricerca in corso..."
    
    result=$(python3 - <<PY | ssh_domus "python3 $AGENTMEMORY_PROXY"
import json
req = {
    "jsonrpc": "2.0", "id": 1,
    "method": "initialize",
    "params": {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "harness-domus", "version": "0.1.0"}
    }
}
print(json.dumps(req))
req2 = {
    "jsonrpc": "2.0", "id": 2,
    "method": "tools/call",
    "params": {
        "name": "memory_recall",
        "arguments": {
            "query": "$query",
            "limit": 5
        }
    }
}
print(json.dumps(req2))
PY
    )
    
    rofi -dmenu -p "Risultati" -mesg "$result" -lines 0 -width 70 \
        -theme-str 'window { width: 700px; border: 2px; border-color: #00ff41; background-color: #000000; }' \
        -theme-str 'prompt { text-color: #00ff41; }' \
        -theme-str 'entry { text-color: #00ff41; }' \
        <<< ""
}

# Esegui comando
run_command() {
    cmd=$(rofi -dmenu -p "Comando su Domus" -lines 0 -width 60 \
        -theme-str 'window { width: 600px; border: 2px; border-color: #00ff41; background-color: #000000; }' \
        -theme-str 'prompt { text-color: #00ff41; }' \
        -theme-str 'entry { text-color: #00ff41; }')
    [ -z "$cmd" ] && return
    
    output=$(ssh_domus "$cmd" 2>&1)
    rofi -dmenu -p "Output" -mesg "$output" -lines 0 -width 80 \
        -theme-str 'window { width: 800px; height: 500px; border: 2px; border-color: #00ff41; background-color: #000000; }' \
        -theme-str 'prompt { text-color: #00ff41; }' \
        -theme-str 'entry { text-color: #00ff41; }' \
        <<< ""
}

# Statistiche
stats_domus() {
    output=$(ssh_domus 'echo "=== DISK ==="; df -h; echo "=== RAM ==="; free -h; echo "=== LOAD ==="; uptime' 2>&1)
    rofi -dmenu -p "Stats Domus" -mesg "$output" -lines 0 -width 80 \
        -theme-str 'window { width: 800px; height: 500px; border: 2px; border-color: #00ff41; background-color: #000000; }' \
        -theme-str 'prompt { text-color: #00ff41; }' \
        -theme-str 'entry { text-color: #00ff41; }' \
        <<< ""
}

# Backup cyberOS
backup_repo() {
    notify "Backup cyberOS" "Push su Domus in corso..."
    cd "$CYBEROS_REPO" || exit
    if git push domus master 2>&1; then
        notify "Backup cyberOS" "Repo pushato su Domus ✅"
    else
        notify "Backup cyberOS" "Errore nel push su Domus ❌"
    fi
}

# Monta filesystem
mount_domus() {
    mountpoint="/mnt/domus"
    mkdir -p "$mountpoint"
    if mountpoint -q "$mountpoint"; then
        notify "Domus mount" "Già montato in $mountpoint"
    else
        if sshfs "$DOMUS:/" "$mountpoint" -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 2>/dev/null; then
            notify "Domus mount" "Montato in $mountpoint"
        else
            notify "Domus mount" "Errore montaggio. sshfs installato?"
        fi
    fi
}

# Apri browser
open_browser() {
    firefox "http://$DOMUS_IP" &
}

# Main
choice=$(main_menu | "${rofi_cmd[@]}")
[ -z "$choice" ] && exit 0

case "$choice" in
    *"Status Domus"*)      status_domus ;;
    *"salva nota"*)        am_save ;;
    *"ricerca"*)           am_search ;;
    *"Esegui comando"*)    run_command ;;
    *"Statistiche"*)       stats_domus ;;
    *"Backup cyberOS"*)    backup_repo ;;
    *"Monta filesystem"*)  mount_domus ;;
    *"Apri IP Domus"*)     open_browser ;;
    *) exit 0 ;;
esac
