#!/bin/bash
# backup.sh — Aggiorna il repo cyberOS dal sistema attuale.
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

echo "[cyberOS-backup] Aggiornamento repo dal sistema..."

# home configs
mkdir -p home/user/.config/{i3,polybar,rofi,dunst,picom,alacritty}
mkdir -p home/user/.local/bin
mkdir -p home/user/Pictures
cp -v ~/.config/i3/config home/user/.config/i3/
cp -v ~/.config/i3/keybindings.md home/user/.config/i3/
cp -v ~/.config/i3/help.txt home/user/.config/i3/
cp -v ~/.config/polybar/config.ini home/user/.config/polybar/
cp -v ~/.config/rofi/config.rasi home/user/.config/rofi/
cp -v ~/.config/dunst/dunstrc home/user/.config/dunst/
cp -v ~/.config/picom/picom.conf home/user/.config/picom/
cp -v ~/.config/alacritty/alacritty.toml home/user/.config/alacritty/
cp -v ~/.bash_aliases home/user/
cp -v ~/.bashrc home/user/.bashrc.orig
[ -f ~/.local/bin/polybar-wireguard.sh ] && cp -v ~/.local/bin/polybar-wireguard.sh home/user/.local/bin/
[ -f ~/Pictures/wallpaper-custom.jpg ] && cp -v ~/Pictures/wallpaper-custom.jpg home/user/Pictures/

# system configs
mkdir -p system/etc/{systemd/system,systemd/journald.conf.d,sysctl.d,apt/apt.conf.d}
sudo cp -v /etc/fstab system/etc/
sudo cp -v /etc/systemd/system/ram-home.service system/etc/systemd/system/
sudo cp -v /etc/systemd/system/ram-home-save.service system/etc/systemd/system/
sudo cp -v /etc/systemd/system/ram-home-save.timer system/etc/systemd/system/
[ -f /etc/systemd/system/ram-home-shutdown.service ] && sudo cp -v /etc/systemd/system/ram-home-shutdown.service system/etc/systemd/system/
sudo cp -v /etc/systemd/system/zram.service system/etc/systemd/system/
[ -f /etc/sudoers.d/wireguard-polybar ] && sudo cp -v /etc/sudoers.d/wireguard-polybar system/etc/sudoers.d/
sudo cp -v /etc/systemd/journald.conf.d/99-ram.conf system/etc/systemd/journald.conf.d/
sudo cp -v /etc/sysctl.d/99-live.conf system/etc/sysctl.d/
sudo cp -v /etc/apt/apt.conf.d/99-live system/etc/apt/apt.conf.d/
sudo cp -v /etc/apt/sources.list system/etc/apt/

mkdir -p system/usr/local/{bin,sbin}
sudo cp -v /usr/local/sbin/ram-home.sh system/usr/local/sbin/
sudo cp -v /usr/local/sbin/zram-setup.sh system/usr/local/sbin/
sudo cp -v /usr/local/bin/telegram system/usr/local/bin/
sudo cp -v /usr/local/bin/persist-save system/usr/local/bin/
[ -f /usr/local/bin/clipnotify ] && sudo cp -v /usr/local/bin/clipnotify system/usr/local/bin/
[ -f /usr/local/bin/sync-to-nvme.sh ] && sudo cp -v /usr/local/bin/sync-to-nvme.sh system/usr/local/bin/

mkdir -p home/user/.local/bin
for script in launch-polybar.sh polybar-hover-monitor.sh polybar-wireguard.sh polybar-bluetooth.sh polybar-kdeconnect.sh bluetooth-menu.sh sync-to-nvme.sh standby.sh power-menu.sh kdeconnect-menu.sh domus-chat.sh setup-domus-chat-profile.sh clipmenu-rofi.sh; do
    [ -f "$HOME/.local/bin/$script" ] && cp -v "$HOME/.local/bin/$script" home/user/.local/bin/
done

mkdir -p system/etc/systemd/user/clipmenud.service.d
sudo cp -v /etc/systemd/user/clipmenud.service.d/override.conf system/etc/systemd/user/clipmenud.service.d/

# wireguard config (contiene chiavi private: repo privato)
mkdir -p system/etc/wireguard
[ -f /etc/wireguard/PzBench.conf ] && sudo cp -v /etc/wireguard/PzBench.conf system/etc/wireguard/

# boot configs from live medium
mkdir -p boot/live-medium/boot/grub boot/live-medium/isolinux
sudo cp -v /run/live/medium/boot/grub/grub.cfg boot/live-medium/boot/grub/ 2>/dev/null || true
sudo cp -v /run/live/medium/boot/grub/config.cfg boot/live-medium/boot/grub/ 2>/dev/null || true
sudo cp -v /run/live/medium/isolinux/isolinux.cfg boot/live-medium/isolinux/ 2>/dev/null || true
sudo cp -v /run/live/medium/isolinux/menu.cfg boot/live-medium/isolinux/ 2>/dev/null || true
sudo cp -v /run/live/medium/isolinux/live.cfg boot/live-medium/isolinux/ 2>/dev/null || true

# package lists
apt-mark showmanual > packages_manual.list
dpkg --get-selections > packages_all.list

# docs
[ -f ~/aiReports/DebianPz_Cyberpunk_Workbench_Report.md ] && \
    cp -v ~/aiReports/DebianPz_Cyberpunk_Workbench_Report.md docs/

echo "[cyberOS-backup] Fatto. Esegui 'git status' per vedere le differenze."
