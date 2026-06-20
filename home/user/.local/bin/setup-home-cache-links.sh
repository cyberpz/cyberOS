#!/bin/bash
# Link heavy cache dirs to NVMe persistence to free RAM in /home/user tmpfs

set -e

CACHE_BASE="/run/live/persistence/nvme0n1p2/home-cache"

# Fallback: try to find persistence mount if nvme0n1p2 name changes
if [ ! -d "$CACHE_BASE" ]; then
    PERSIST_BASE=$(findmnt -n -o TARGET /run/live/persistence/* 2>/dev/null | head -n1)
    if [ -n "$PERSIST_BASE" ]; then
        CACHE_BASE="$PERSIST_BASE/home-cache"
    fi
fi

if [ ! -d "$CACHE_BASE" ]; then
    echo "[!] Persistence cache base not found: $CACHE_BASE"
    exit 1
fi

mkdir -p "$CACHE_BASE"

link_dir() {
    local src="$1"
    local name="$2"
    local dst="$CACHE_BASE/$name"

    mkdir -p "$(dirname "$src")"
    mkdir -p "$dst"

    if [ -L "$src" ]; then
        echo "[*] $src already symlink"
        return
    fi

    if [ -d "$src" ] && [ "$(ls -A "$src" 2>/dev/null)" ]; then
        echo "[*] Moving $src contents to $dst"
        rsync -a --remove-source-files "$src/" "$dst/"
        rm -rf "$src"
    fi

    [ -e "$src" ] && rm -rf "$src"
    ln -s "$dst" "$src"
    echo "[OK] $src -> $dst"
}

link_dir "/home/user/.kimi-code/bin"            "kimi-code-bin"
link_dir "/home/user/.opencode/bin"             "opencode-bin"
link_dir "/home/user/.opencode/node_modules"    "opencode-node_modules"
link_dir "/home/user/.local/lib/python3.13"     "python3.13"
link_dir "/home/user/.local/share/opencode"     "opencode-share"
link_dir "/home/user/.local/share/luakit"       "luakit-share"

# The following are safe to move when no npm/gradle/flutter build is running
link_dir "/home/user/.npm"                      "npm"
link_dir "/home/user/.gradle"                   "gradle"
link_dir "/home/user/.pub-cache"                "pub-cache"
link_dir "/home/user/Downloads"                 "Downloads"
link_dir "/home/user/.config/opencode"          "opencode-config"
link_dir "/home/user/.cache/uv"                 "uv-cache"

# Gradle cache specifica dei progetti in RAM
link_dir "/home/user/Projects/.gradle"          "projects-gradle"
link_dir "/home/user/Projects/.repowise-venv"   "projects-repowise-venv"

echo "[OK] Home cache links ready."
