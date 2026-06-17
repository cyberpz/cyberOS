#!/bin/bash
# install.sh — Ripristina il cyberOS DebianPz su una nuova live USB Debian.
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_HOME="/home/user"
LIVE_MEDIUM="/run/live/medium"

echo "[cyberOS] Inizio ripristino configurazioni..."

# 1. Installa pacchetti apt
if [ -f "$REPO_DIR/packages_curated.list" ]; then
    echo "[cyberOS] Installazione pacchetti apt..."
    sudo apt-get update
    xargs -a "$REPO_DIR/packages_curated.list" sudo apt-get install -y
fi

# 2. Dotfiles utente
echo "[cyberOS] Copia configurazioni utente..."
mkdir -p "$USER_HOME/.config"
rsync -av "$REPO_DIR/home/user/" "$USER_HOME/"

# 3. Script e file di sistema
echo "[cyberOS] Copia file di sistema..."
sudo rsync -av "$REPO_DIR/system/" /

# 4. Permessi script
sudo chmod +x /usr/local/sbin/ram-home.sh
sudo chmod +x /usr/local/sbin/zram-setup.sh
sudo chmod +x /usr/local/bin/telegram
sudo chmod +x /usr/local/bin/persist-save
[ -f /usr/local/bin/clipnotify ] && sudo chmod +x /usr/local/bin/clipnotify
find "$USER_HOME/.local/bin" -maxdepth 1 -type f -exec chmod +x {} \;

# 4b. WireGuard config (contiene chiavi private)
if [ -f "$REPO_DIR/system/etc/wireguard/PzBench.conf" ]; then
    echo "[cyberOS] Installazione configurazione WireGuard..."
    sudo mkdir -p /etc/wireguard
    sudo cp -v "$REPO_DIR/system/etc/wireguard/PzBench.conf" /etc/wireguard/
    sudo chmod 600 /etc/wireguard/PzBench.conf
    sudo chown root:root /etc/wireguard/PzBench.conf
fi

# 5. Telegram Desktop in /opt
if [ ! -d /opt/Telegram ]; then
    echo "[cyberOS] Installazione Telegram Desktop in /opt/Telegram..."
    sudo mkdir -p /opt
    cd /tmp
    wget -q -O telegram.tar.xz "https://telegram.org/dl/desktop/linux"
    sudo tar -xJf telegram.tar.xz -C /opt
    sudo ln -sf /opt/Telegram/Telegram /opt/Telegram/telegram 2>/dev/null || true
    cd "$REPO_DIR"
fi

# 6. clipmenu (se non presente)
if ! command -v clipmenu >/dev/null 2>&1; then
    echo "[cyberOS] Compilazione clipmenu + clipnotify..."
    sudo apt-get install -y libxfixes-dev libx11-dev
    cd /tmp
    git clone --depth 1 https://github.com/cdown/clipmenu.git 2>/dev/null || true
    cd clipmenu
    make
    sudo make install
    cd "$REPO_DIR"
fi

# 7. Abilita servizi systemd
sudo systemctl daemon-reload
sudo systemctl enable ram-home.service
sudo systemctl enable ram-home-save.timer
[ -f /etc/systemd/system/ram-home-shutdown.service ] && sudo systemctl enable ram-home-shutdown.service
sudo systemctl enable zram.service

# 8. Applica sysctl
sudo sysctl --system

# 9. Bootloader della chiavetta (opzionale, richiede medium RW)
if mountpoint -q "$LIVE_MEDIUM"; then
    echo "[cyberOS] La chiavetta è montata in $LIVE_MEDIUM (probabilmente read-only)."
    echo "[cyberOS] Per applicare le modifiche al bootloader, montala in RW e copia:"
    echo "    sudo mount -o remount,rw $LIVE_MEDIUM"
    echo "    sudo rsync -av $REPO_DIR/boot/live-medium/ $LIVE_MEDIUM/"
    echo "[cyberOS] Salta il ripristino del bootloader per ora."
else
    echo "[cyberOS] Chiavetta non montata in $LIVE_MEDIUM; salto bootloader."
fi

echo "[cyberOS] Ripristino completato. Riavvia o esegui: sudo systemctl start ram-home zram"
