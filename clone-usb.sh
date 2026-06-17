#!/bin/bash
# clone-usb.sh — Ripristina il backup DebianPz su una nuova chiavetta USB,
#                espandendo automaticamente la persistenza se c'è spazio.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOUNT_BASE="/mnt/clone-usb-temp"

# Colori
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

# Controlla dipendenze
for cmd in dd sfdisk fsarchiver parted resize2fs e2fsck partprobe lsblk blockdev numfmt mount umount; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error "Comando richiesto non trovato: $cmd"
        exit 1
    fi
done

clear
echo "=========================================="
echo "  DebianPz USB Clone Tool"
echo "=========================================="
echo ""

# --- FASE 1: trova o monta il backup ---

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

# Cerca backup già montati
BACKUP_DIR=""
for candidate in /mnt/hdd/cyberOS-images /media/*/cyberOS-images /mnt/*/cyberOS-images "$SCRIPT_DIR"/cyberOS-images; do
    if [ -d "$candidate" ] && find_backup_files "$candidate" >/dev/null 2>&1; then
        BACKUP_DIR="$candidate"
        info "Backup trovato in: $BACKUP_DIR"
        break
    fi
done

# Se non trovato, chiede all'utente di montare un disco
if [ -z "$BACKUP_DIR" ]; then
    warn "Backup non trovato automaticamente."
    echo ""
    echo "Dischi/partizioni disponibili:"
    echo ""
    printf " %-4s %-12s %-10s %-30s\n" "N" "DEVICE" "SIZE" "FSTYPE"
    echo " --------------------------------------------------------------"

    mapfile -t DEVICES < <(lsblk -dpno PATH,SIZE,FSTYPE,TYPE | awk '$4=="part" || $4=="disk" {print $1":"$2":"$3":"$4}')
    i=1
    declare -A DEV_MAP
    for dev in "${DEVICES[@]}"; do
        path=$(echo "$dev" | cut -d: -f1)
        size=$(echo "$dev" | cut -d: -f2)
        fstype=$(echo "$dev" | cut -d: -f3)
        type=$(echo "$dev" | cut -d: -f4)
        # Salta il disco di sistema live e zram
        if [[ "$path" == /dev/zram* ]] || [[ "$path" == /dev/loop* ]]; then
            continue
        fi
        # Per i dischi, mostra solo se hanno partizioni
        if [ "$type" = "disk" ]; then
            parts=$(lsblk -dn -o PATH "$path" | tail -n +2 | wc -l)
            [ "$parts" -gt 0 ] && continue
        fi
        printf " %-4s %-12s %-10s %-30s\n" "$i" "$path" "$size" "$fstype"
        DEV_MAP[$i]="$path"
        ((i++))
    done

    echo ""
    read -r -p "Scegli il numero del device da montare (o Invio per saltare): " CHOICE
    if [ -n "$CHOICE" ] && [ -n "${DEV_MAP[$CHOICE]}" ]; then
        SELECTED_DEV="${DEV_MAP[$CHOICE]}"
        mkdir -p "$MOUNT_BASE"
        umount "$MOUNT_BASE" 2>/dev/null || true
        echo ""
        info "Montaggio di $SELECTED_DEV in $MOUNT_BASE..."
        if mount "$SELECTED_DEV" "$MOUNT_BASE" 2>/dev/null || ntfs-3g -o rw "$SELECTED_DEV" "$MOUNT_BASE" 2>/dev/null; then
            if find_backup_files "$MOUNT_BASE" >/dev/null 2>&1; then
                BACKUP_DIR="$MOUNT_BASE"
                info "Backup trovato nel disco montato."
            else
                # Cerca in sottocartelle
                for sub in "$MOUNT_BASE"/*; do
                    if [ -d "$sub" ] && find_backup_files "$sub" >/dev/null 2>&1; then
                        BACKUP_DIR="$sub"
                        info "Backup trovato in: $BACKUP_DIR"
                        break
                    fi
                done
            fi
        else
            error "Impossibile montare $SELECTED_DEV"
            exit 1
        fi
    fi
fi

if [ -z "$BACKUP_DIR" ]; then
    error "Nessun backup trovato. Assicurati di avere i file *_mbr.bin, *_sdc.sfdisk, *.fsa"
    exit 1
fi

MBR=$(ls -1 "$BACKUP_DIR"/*_mbr.bin 2>/dev/null | sort | tail -1)
SFDISK=$(ls -1 "$BACKUP_DIR"/*_sdc.sfdisk 2>/dev/null | sort | tail -1)
FSA=$(ls -1 "$BACKUP_DIR"/*.fsa 2>/dev/null | sort | tail -1)

echo ""
echo "Backup selezionato:"
echo "  Directory: $BACKUP_DIR"
echo "  MBR:      $(basename "$MBR")"
echo "  Sfdisk:   $(basename "$SFDISK")"
echo "  Archive:  $(basename "$FSA") ($(stat -c%s "$FSA" | numfmt --to=iec-i))"
echo ""

# --- FASE 2: scegli il target USB ---

echo "Chiavette USB/dischi target disponibili:"
echo ""
printf " %-4s %-12s %-10s %-40s\n" "N" "DEVICE" "SIZE" "MODEL"
echo " ----------------------------------------------------------------"

mapfile -t DISKS < <(lsblk -dpno PATH,SIZE,MODEL,TYPE | awk '$4=="disk" {print $1":"$2":"$3}')
i=1
declare -A TARGET_MAP
for disk in "${DISKS[@]}"; do
    path=$(echo "$disk" | cut -d: -f1)
    size=$(echo "$disk" | cut -d: -f2)
    model=$(echo "$disk" | cut -d: -f3)
    # Salta il disco di sistema live (quello da cui abbiamo bootato)
    if lsblk -dn -o MOUNTPOINT "$path" | grep -qE '^/$|^/run/live'; then
        continue
    fi
    # Salta il disco del backup se montato
    if mountpoint -q "$BACKUP_DIR" 2>/dev/null; then
        backup_dev=$(findmnt -n -o SOURCE "$BACKUP_DIR" 2>/dev/null || true)
        if [ "$backup_dev" = "$path" ]; then
            continue
        fi
    fi
    printf " %-4s %-12s %-10s %-40s\n" "$i" "$path" "$size" "$model"
    TARGET_MAP[$i]="$path"
    ((i++))
done

echo ""
read -r -p "Scegli il numero del device target: " TARGET_CHOICE
if [ -z "$TARGET_CHOICE" ] || [ -z "${TARGET_MAP[$TARGET_CHOICE]}" ]; then
    error "Scelta non valida."
    exit 1
fi
TARGET="${TARGET_MAP[$TARGET_CHOICE]}"
TARGET_SIZE=$(blockdev --getsize64 "$TARGET")

echo ""
echo "Hai scelto: $TARGET ($(numfmt --to=iec-i "$TARGET_SIZE"))"
echo ""

# --- FASE 3: conferma ---

warn "Tutti i dati su $TARGET verranno CANCELLATI."
read -r -p "Scrivi 'yes' per procedere: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    info "Operazione annullata."
    exit 0
fi

# --- FASE 4: clone ---

# Smonta eventuali partizioni del target
sync
for p in $(lsblk -dn -o PATH "$TARGET" | tail -n +2); do
    umount "$p" 2>/dev/null || true
done

info "[1/5] Scrittura MBR e tabella partizioni..."
dd if="$MBR" of="$TARGET" bs=512 count=1 status=progress
sfdisk "$TARGET" < "$SFDISK"
partprobe "$TARGET" 2>/dev/null || true
sleep 2

info "[2/5] Ripristino partizioni con fsarchiver..."
fsarchiver -A restfs "$FSA" id=0,dest="${TARGET}1" id=1,dest="${TARGET}2"

partprobe "$TARGET" 2>/dev/null || true
sleep 2

# --- FASE 5: espansione persistenza ---

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

# --- FASE 6: verifica ---

echo ""
echo "Verifica archivio:"
fsarchiver archinfo "$FSA"
echo ""
echo "Tabella partizioni finale:"
parted -s "$TARGET" print

echo ""
echo -e "${GREEN}✅ Clone completato su $TARGET${NC}"
echo "Puoi avviare dalla nuova chiavetta."
