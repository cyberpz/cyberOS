#!/bin/bash
# clone-to.sh — Clona il backup DebianPz su un disco target in modo non interattivo.
#               Espande automaticamente la persistenza se c'è spazio.
#
# Uso: sudo ./clone-to.sh <target-device> [backup-dir]
# Esempio: sudo ./clone-to.sh /dev/sde

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOUNT_BASE="/mnt/clone-usb-temp"
PATH="/usr/sbin:/sbin:$PATH"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[AVVISO]${NC} $*"; }
error() { echo -e "${RED}[ERRORE]${NC} $*" >&2; }

# Controlla root
if [ "$(id -u)" -ne 0 ]; then
    error "Questo script deve essere eseguito come root (usa sudo)."
    exit 1
fi

# Dipendenze
for cmd in dd sfdisk fsarchiver parted resize2fs e2fsck partprobe lsblk blockdev numfmt mount umount; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error "Comando richiesto non trovato: $cmd"
        exit 1
    fi
done

# Argomenti
TARGET="${1:-}"
BACKUP_DIR_ARG="${2:-}"

if [ -z "$TARGET" ]; then
    error "Target non specificato."
    echo "Uso: sudo $0 <target-device> [backup-dir]"
    echo "Esempio: sudo $0 /dev/sde"
    exit 1
fi

if [ ! -b "$TARGET" ]; then
    error "$TARGET non è un device a blocchi valido."
    exit 1
fi

# Non permettere di cancellare il disco di boot live
if lsblk -dn -o MOUNTPOINT "$TARGET" | grep -qE '^/$|^/run/live'; then
    error "$TARGET è il disco di sistema live. Non posso clonarci sopra."
    exit 1
fi

find_backup_files() {
    local dir="$1"
    local mbr sfdisk fsa
    mbr=$(ls -1 "$dir"/*_mbr.bin 2>/dev/null | sort | tail -1 || true)
    sfdisk=$(ls -1 "$dir"/*_sdc.sfdisk 2>/dev/null | sort | tail -1 || true)
    fsa=$(ls -1 "$dir"/*.fsa 2>/dev/null | sort | tail -1 || true)
    if [ -n "$mbr" ] && [ -n "$sfdisk" ] && [ -n "$fsa" ]; then
        echo "$dir"
        return 0
    fi
    return 1
}

# Trova backup
BACKUP_DIR=""
if [ -n "$BACKUP_DIR_ARG" ] && [ -d "$BACKUP_DIR_ARG" ] && find_backup_files "$BACKUP_DIR_ARG" >/dev/null 2>&1; then
    BACKUP_DIR="$BACKUP_DIR_ARG"
    info "Backup fornito dall'utente: $BACKUP_DIR"
else
    for candidate in /mnt/hdd/cyberOS-images /media/*/cyberOS-images /mnt/*/cyberOS-images "$SCRIPT_DIR"/cyberOS-images; do
        if [ -d "$candidate" ] && find_backup_files "$candidate" >/dev/null 2>&1; then
            BACKUP_DIR="$candidate"
            info "Backup trovato automaticamente in: $BACKUP_DIR"
            break
        fi
    done
fi

if [ -z "$BACKUP_DIR" ]; then
    error "Nessun backup trovato. Fornisci [backup-dir] o monta il disco di backup."
    exit 1
fi

MBR=$(ls -1 "$BACKUP_DIR"/*_mbr.bin 2>/dev/null | sort | tail -1)
SFDISK=$(ls -1 "$BACKUP_DIR"/*_sdc.sfdisk 2>/dev/null | sort | tail -1)
FSA=$(ls -1 "$BACKUP_DIR"/*.fsa 2>/dev/null | sort | tail -1)

info "Backup selezionato:"
echo "  Directory: $BACKUP_DIR"
echo "  MBR:      $(basename "$MBR")"
echo "  Sfdisk:   $(basename "$SFDISK")"
echo "  Archive:  $(basename "$FSA") ($(stat -c%s "$FSA" | numfmt --to=iec-i))"
echo "  Target:   $TARGET ($(blockdev --getsize64 "$TARGET" | numfmt --to=iec-i))"
echo ""

warn "Tutti i dati su $TARGET verranno CANCELLATI in 5 secondi..."
sleep 5

# Pulizia aggressiva del target
sync
info "Smontaggio e pulizia processi sul target..."
# Uccidi eventuali fsarchiver che stanno usando il target
for pid in $(pgrep -f "fsarchiver.*${TARGET}" 2>/dev/null || true); do
    kill -TERM "$pid" 2>/dev/null || true
done
sleep 2
for pid in $(pgrep -f "fsarchiver.*${TARGET}" 2>/dev/null || true); do
    kill -KILL "$pid" 2>/dev/null || true
done
# Smonta eventuali mountpoint fsarchiver residui
for mp in /tmp/fsa/*; do
    if mountpoint -q "$mp" 2>/dev/null; then
        umount -l "$mp" 2>/dev/null || true
    fi
done
# Smonta partizioni del target
for p in $(lsblk -dn -o PATH "$TARGET" | tail -n +2); do
    umount "$p" 2>/dev/null || true
    umount -l "$p" 2>/dev/null || true
done
sync
sleep 1

info "[1/5] Scrittura MBR e tabella partizioni..."
dd if="$MBR" of="$TARGET" bs=512 count=1 status=progress
sfdisk --force "$TARGET" < "$SFDISK"
partprobe "$TARGET" 2>/dev/null || true
sleep 2

info "[2/5] Ripristino partizioni con fsarchiver..."
FSARCHIVER_OPTS=""
# Usa tutti i core disponibili per velocizzare
if fsarchiver --help 2>&1 | grep -q -- "-j"; then
    FSARCHIVER_OPTS="-j$(nproc)"
fi
fsarchiver $FSARCHIVER_OPTS -A restfs "$FSA" id=0,dest="${TARGET}1" id=1,dest="${TARGET}2"

partprobe "$TARGET" 2>/dev/null || true
sleep 2

info "[3/5] Verifica spazio libero per espansione persistenza..."
TARGET_SIZE=$(blockdev --getsize64 "$TARGET")
LAST_PART_END=$(parted -ms "$TARGET" unit B print free 2>/dev/null | awk -F: '/^[0-9]+:.*free/ {end=$2} END {print end}' | tr -d 'B' || true)

if [ -n "$LAST_PART_END" ] && [ "$LAST_PART_END" -lt "$TARGET_SIZE" ]; then
    FREE_SPACE=$((TARGET_SIZE - LAST_PART_END))
    info "Spazio libero rilevato: $(numfmt --to=iec-i "$FREE_SPACE")"
    info "[4/5] Espansione partizione 2 (persistence)..."
    parted -s "$TARGET" resizepart 2 100%
    partprobe "$TARGET" 2>/dev/null || true
    sleep 2
    e2fsck -f -p "${TARGET}2" || true
    resize2fs "${TARGET}2"
    info "[5/5] Persistenza espansa con successo."
else
    info "[4/5] Nessuno spazio libero dopo l'ultima partizione. Espansione non necessaria."
fi

# Verifica finale
echo ""
echo "Verifica archivio:"
fsarchiver archinfo "$FSA"
echo ""
echo "Tabella partizioni finale:"
parted -s "$TARGET" print

echo ""
echo -e "${GREEN}✅ Clone completato su $TARGET${NC}"
