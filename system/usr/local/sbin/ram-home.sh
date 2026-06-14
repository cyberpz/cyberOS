#!/bin/bash
# Mount /home/user in RAM and provide explicit persistence on the live USB.

set -e

USER_HOME=/home/user
RAM_SIZE=4G

# Find live persistence mount point
PERSIST_BASE=$(findmnt -n -o TARGET /run/live/persistence/* 2>/dev/null | head -n1)
[ -z "$PERSIST_BASE" ] && PERSIST_BASE=/run/live/persistence/sdc2
PERSIST_DIR="$PERSIST_BASE/ram-home-backup"
DISABLE_FLAG="$PERSIST_DIR/DISABLE"

# Directory ingombranti e facilmente ricreabili da escludere
EXCLUDE_LIST=(
    ".cache"
    "tmp"
    ".local/share/Trash"
    ".thumbnails"
    ".npm"
    ".kimi-code/logs"
    ".kimi-code/telemetry"
    ".kimi-code/updates"
    ".kimi-code/bin"
    ".config/opencode"
    # ".mozilla"  # profilo firefox: meglio conservarlo
)

log() {
    echo "[ram-home] $*" >&2
}

build_rsync_excludes() {
    local args=""
    for ex in "${EXCLUDE_LIST[@]}"; do
        args="$args --exclude=\"$ex\""
    done
    echo "$args"
}

do_start() {
    if [ -f "$DISABLE_FLAG" ]; then
        log "DISABLE flag found, skipping RAM home mount"
        exit 0
    fi

    mkdir -p "$PERSIST_DIR"

    # Already a tmpfs? Nothing to do
    if mountpoint -q "$USER_HOME"; then
        log "$USER_HOME is already a mountpoint"
        exit 0
    fi

    # If no saved home exists, back up the current one first
    if [ ! -d "$PERSIST_DIR/home" ] && [ -d "$USER_HOME" ]; then
        log "Creating initial persistent home backup"
        mkdir -p "$PERSIST_DIR/home"
        # shellcheck disable=SC2086
        rsync -a --delete \
            $(build_rsync_excludes) \
            "$USER_HOME/" "$PERSIST_DIR/home/"
    fi

    # Mount tmpfs and restore
    mount -t tmpfs -o size=$RAM_SIZE,mode=0755,uid=1000,gid=1000 tmpfs "$USER_HOME"

    if [ -d "$PERSIST_DIR/home" ]; then
        log "Restoring RAM home from $PERSIST_DIR/home"
        # -W = whole-file, più veloce su supporti lenti quando non serve il delta
        # shellcheck disable=SC2086
        rsync -aW --delete \
            $(build_rsync_excludes) \
            "$PERSIST_DIR/home/" "$USER_HOME/"
    else
        log "No persistent home found, starting with empty tmpfs"
    fi

    log "RAM home mounted at $USER_HOME"
}

do_save() {
    if [ -f "$DISABLE_FLAG" ]; then
        log "DISABLE flag found, skipping save"
        exit 0
    fi
    if mountpoint -q "$USER_HOME"; then
        log "Saving RAM home to $PERSIST_DIR/home"
        mkdir -p "$PERSIST_DIR/home"
        # shellcheck disable=SC2086
        rsync -a --delete \
            $(build_rsync_excludes) \
            "$USER_HOME/" "$PERSIST_DIR/home/"
    else
        log "$USER_HOME is not a tmpfs, nothing to save"
    fi
}

case "$1" in
    start) do_start ;;
    stop|save) do_save ;;
    *) echo "Usage: $0 {start|stop|save}"; exit 1 ;;
esac
