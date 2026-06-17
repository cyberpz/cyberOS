#!/bin/bash
# sync-to-nvme.sh — Aggiorna incrementale la NVMe /dev/sde con le modifiche del sistema attuale.
# Non ricrea l'immagine fsarchiver: copia solo i file cambiati.
#
# Uso: sudo ./sync-to-nvme.sh [target-device]

set -e

TARGET="${1:-/dev/sde}"
MNT_PERSIST="/mnt/nvme-persist"
MNT_BOOT="/mnt/nvme-boot"

if [ "$(id -u)" -ne 0 ]; then
    echo "Esegui come root (usa sudo)." >&2
    exit 1
fi

if [ ! -b "$TARGET" ]; then
    echo "$TARGET non è un device valido." >&2
    exit 1
fi

# Evita di sincronizzare sul disco di boot live
if lsblk -dn -o MOUNTPOINT "$TARGET" | grep -qE '^/$|^/run/live'; then
    echo "$TARGET è il disco live attuale." >&2
    exit 1
fi

mkdir -p "$MNT_PERSIST" "$MNT_BOOT"

# Smonta e rimonta
umount "$MNT_PERSIST" 2>/dev/null || true
umount "$MNT_BOOT" 2>/dev/null || true
mount "${TARGET}2" "$MNT_PERSIST"
mount "${TARGET}1" "$MNT_BOOT"

cleanup() {
    umount "$MNT_PERSIST" 2>/dev/null || true
    umount "$MNT_BOOT" 2>/dev/null || true
}
trap cleanup EXIT

echo "[sync-to-nvme] Sincronizzazione file di sistema..."
# Servizi systemd
mkdir -p "$MNT_PERSIST/rw/etc/systemd/system"
mkdir -p "$MNT_PERSIST/rw/etc/systemd/system/multi-user.target.wants"
mkdir -p "$MNT_PERSIST/rw/etc/systemd/system/swap.target.wants"

rsync -a --delete system/etc/systemd/system/ "$MNT_PERSIST/rw/etc/systemd/system/"

# sudoers
mkdir -p "$MNT_PERSIST/rw/etc/sudoers.d"
rsync -a --delete system/etc/sudoers.d/ "$MNT_PERSIST/rw/etc/sudoers.d/"
chmod 440 "$MNT_PERSIST"/rw/etc/sudoers.d/*

# wireguard config (se presente sul sistema attuale)
if [ -f /etc/wireguard/PzBench.conf ]; then
    mkdir -p "$MNT_PERSIST/rw/etc/wireguard"
    cp -a /etc/wireguard/PzBench.conf "$MNT_PERSIST/rw/etc/wireguard/PzBench.conf"
    chmod 600 "$MNT_PERSIST/rw/etc/wireguard/PzBench.conf"
fi

# fstab, sysctl, apt
for f in system/etc/fstab system/etc/sysctl.d system/etc/apt; do
    if [ -e "$f" ]; then
        target="$MNT_PERSIST/rw/${f#system/}"
        mkdir -p "$(dirname "$target")"
        rsync -a "$f" "$target"
    fi
done

echo "[sync-to-nvme] Sincronizzazione home utente..."
mkdir -p "$MNT_PERSIST/ram-home-backup/home/user"
rsync -a --delete \
    --exclude='.cache' \
    --exclude='tmp' \
    --exclude='.local/share/Trash' \
    --exclude='.thumbnails' \
    --exclude='.npm' \
    --exclude='.kimi-code/logs' \
    --exclude='.kimi-code/telemetry' \
    --exclude='.kimi-code/updates' \
    --exclude='.kimi-code/bin' \
    --exclude='.config/opencode' \
    /home/user/ "$MNT_PERSIST/ram-home-backup/home/user/"

echo "[sync-to-nvme] Fatto. NVMe allineata con il sistema attuale."
