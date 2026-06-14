# cyberOS — DebianPz Cyberpunk Workbench

Backup/recovery repository per il sistema operativo Debian live USB personalizzato.

## Scopo

Questo repo contiene tutti i file di configurazione, script e documentazione necessari a ricreare l'ambiente **DebianPz Cyberpunk Workbench** su una nuova chiavetta USB Debian live, nel caso la chiavetta attuale venga persa o danneggiata.

## Struttura

```
cyberOS/
├── home/user/              # Configurazioni utente (dotfiles)
├── system/                 # File di sistema modificati
├── boot/live-medium/       # Configurazioni di boot sulla chiavetta USB
├── docs/                   # Documentazione e report
├── packages_all.list       # Tutti i pacchetti installati (dpkg --get-selections)
├── packages_manual.list    # Pacchetti marcati manualmente (apt-mark showmanual)
├── packages_curated.list   # Pacchetti rilevanti per il workbench
├── install.sh              # Script per ripristinare le configurazioni
└── backup.sh               # Script per aggiornare questo repo dal sistema attuale
```

## Requisiti

- Una chiavetta USB con Debian Trixie/testing live + persistenza abilitata.
- Spazio sufficiente per installare i pacchetti elencati in `packages_curated.list`.
- Accesso root (`sudo`) per copiare file di sistema e abilitare servizi.

## Uso

### Ripristino su nuova installazione live

```bash
cd /home/user/cyberOS
sudo ./install.sh
```

Lo script:
1. Installa i pacchetti necessari.
2. Copia i dotfiles in `/home/user`.
3. Copia i file di sistema in `/etc`, `/usr/local` e abilita i servizi.
4. Configura ZRAM come swap compressa.
5. Monta `/home/user` in RAM con persistenza periodica.
6. Applica le modifiche al bootloader della chiavetta USB (richiede montaggio RW del medium).

### Aggiornare il backup

Dopo aver modificato il sistema, aggiornare il repo:

```bash
cd /home/user/cyberOS
./backup.sh
```

Poi committare e pushare:

```bash
git add .
git commit -m "aggiornamento configurazioni"
git push
```

## Componenti principali

- **Window manager:** i3wm
- **Barra:** polybar (sempre in primo piano)
- **Compositor:** picom
- **Notifiche:** dunst
- **Launcher:** rofi
- **Terminale:** alacritty
- **Browser:** Firefox ESR
- **Chat:** Telegram Desktop
- **Screenshot:** Flameshot
- **Clipboard history:** clipmenu + clipnotify + rofi
- **VPN:** WireGuard (`wg-quick`)

## Ottimizzazioni

- Rimosso `toram` per liberare ~3.8 GB di RAM.
- GRUB/isolinux con `timeout=0` (boot diretto).
- `/home/user` su tmpfs 4 GB con salvataggio ogni 10 min.
- `/tmp`, `/var/tmp`, `/var/log`, `/var/cache`, `~/.cache` su tmpfs.
- ZRAM 4 GB come swap compressa.
- `noatime` sul root overlay.
- Journald in modalità volatile.

## Note

- I file in `boot/live-medium/` devono essere copiati sulla partizione VFAT della chiavetta (`/dev/sdX1`) quando questa è montata in lettura/scrittura.
- Telegram Desktop è installato in `/opt/Telegram` e non via apt; lo script `install.sh` provvede a scaricarlo.
- `clipnotify` e `clipmenu` sono compilati da sorgente; i binari sono inclusi in `system/usr/local/bin/`.

## Licenza

Configurazioni personali — usa a tuo rischio.
