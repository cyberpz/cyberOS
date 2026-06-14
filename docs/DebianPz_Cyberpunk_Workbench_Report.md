# Report — DebianPz Cyberpunk Workbench

> Data: 2026-06-14  
> Operatore: Kimi Code CLI  
> Azione: costruzione e personalizzazione di un sistema operativo Debian live USB su misura per lavoro/AI/tablet.

---

## Sistema di base

- **Hardware target:** laptop/tablet con penna (Lenovo IdeaPad/Yoga-like, touchpad Synaptics)
- **Distribuzione:** Debian Trixie/testing live USB
- **Kernel:** `6.12.86+deb13-amd64`
- **Ambiente grafico:** i3wm + polybar + picom + dunst
- **Shell:** bash
- **Storage:** live USB con persistenza su `/dev/sdc2`
- **RAM:** 7.1 GB totali
- **Home in RAM:** `/home/user` montato su tmpfs 4 GB, salvato su USB ogni 10 min

---

## Obiettivi raggiunti

1. **Workstation portatile** per AI, coding, chat, note.
2. **Look cyberpunk/Matrix** coordinato (verde `#00ff41` su nero).
3. **Boot rapido** senza menu GRUB.
4. **Uso efficiente della RAM** togliendo `toram` e usando overlay persistence.
5. **Penna/tablet** funzionante con basso sforzo.
6. **Shortcuts veloci** per app e funzioni frequenti.
7. **Multi-clipboard** stile Windows.

---

## Ottimizzazioni boot e persistenza

| Modifica | Motivo |
|----------|--------|
| Rimosso `toram` da GRUB/isolinux | Libera ~3.8 GB di RAM |
| `timeout=0` e `timeout_style=hidden` in GRUB | Boot diretto, nessun menu |
| Root overlay su `/run/live/persistence/sdc2` | Persistenza senza caricare tutto in RAM |
| `/home/user` su tmpfs + `ram-home-save.timer` | Velocità in RAM con backup su USB ogni 10 min |
| `/tmp`, `/var/tmp`, `/var/log`, `/var/cache` in tmpfs | Riduce scritture sulla chiavetta |
| `journald` in `Storage=volatile` | Log solo in RAM |
| `noatime` sul root overlay | Meno scritture |
| ZRAM 4 GB come swap | Più memoria effettiva disponibile |
| `ram-home.sh` esclude cache/logs pesanti | Backup home più piccolo e veloce |

---

## Stack grafico e theming

| Componente | Stile/impostazione |
|------------|-------------------|
| **i3** | Bordi finestre verde Matrix, nessun title bar, focus viola/verde |
| **polybar** | Barra principale + barra hover, icone emoji, testo moduli verde Matrix |
| **rofi** | Tema cyberpunk: font Terminus, bordo neon verde 1-2 px, angoli spigolosi, semi-trasparente |
| **dunst** | Notifiche con bordo verde Matrix |
| **Alacritty** | Terminale principale |
| **picom** | Ombre leggere, trasparenza, fading |

---

## App installate/configurate

| App | Scopo | Shortcut |
|-----|-------|----------|
| **Telegram Desktop** | Client nativo completo | `WIN + t` |
| **Firefox ESR** | Browser full | `WIN + Shift + w` |
| **Alacritty** | Terminale | `WIN + d` |
| **Thunar** | File manager | `WIN + Shift + t` |
| **Flameshot** | Screenshot | `WIN + Shift + s` |
| **Rofi drun** | Launcher app | `WIN + Invio` |
| **clipmenu** | Clipboard history | `WIN + v` |

**Rimossa:** luakit (sostituito da Telegram nativo e Firefox).

---

## Shortcut principali

### App
- `WIN + Invio` → launcher app (rofi)
- `WIN + d` → Alacritty
- `WIN + Shift + w` → Firefox
- `WIN + t` → Telegram
- `WIN + Shift + t` → Thunar
- `WIN + Shift + s` → Flameshot
- `WIN + v` → clipboard history

### Finestre / workspace
- `WIN + frecce` → focus
- `WIN + Shift + frecce` → sposta finestra
- `WIN + 1..0` → workspace
- `WIN + Shift + 1..0` → sposta nel workspace
- `WIN + f` → fullscreen
- `WIN + Shift + spazio` → floating
- `WIN + q` / `WIN + Shift + q` → chiudi/kill
- `WIN + Shift + v` → split verticale
- `WIN + h` → split orizzontale

### Sistema
- `WIN + Shift + c` → reload i3
- `WIN + Shift + r` → restart i3
- `WIN + Shift + e` → esci da i3
- `WIN + ?` → visualizza keybindings

---

## Multi-clipboard (clipmenu)

- **Attivazione:** `WIN + v`
- **Selezione:** `Invio` per incollare direttamente
- **Cancellazione:** `Delete` sulla riga (rimane aperto per cancellazioni multiple)
- **Storico:** illimitato (`CM_MAX_CLIPS=0`)
- **Tema:** box rofi cyberpunk compatto

---

## File di configurazione modificati

- `~/.config/i3/config`
- `~/.config/i3/keybindings.md`
- `~/.config/polybar/config.ini`
- `~/.config/rofi/config.rasi`
- `~/.config/dunst/dunstrc`
- `~/.config/picom/picom.conf`
- `~/.local/bin/clipmenu-rofi.sh`
- `~/.local/bin/launch-polybar.sh`
- `~/.local/bin/fake-desktop-splash.sh`
- `/etc/systemd/user/clipmenud.service.d/override.conf`
- `/usr/local/bin/telegram`
- GRUB/isolinux su `/dev/sdc1`

---

## Stato attuale

- Boot: diretto, nessun menu GRUB
- RAM disponibile: ~2.2 GB con app aperte (molto meglio rispetto al periodo `toram`)
- Persistenza: funzionante su `/dev/sdc2`
- Teming: coordinato in verde Matrix
- Clipboard: funzionante con auto-paste e delete multiplo
- Polybar: sempre visibile in sovrimpressione

---

## Prossime idee

- Wallpaper cyber/Matrix
- Tema Alacritty verde Matrix
- Lock screen stile cyber (`i3lock-color`)
- Avvio automatico app su workspace specifici
- Ottimizzazione penna (pressione, bottoni, xsetwacom)
- Browser profile su tmpfs per ridurre scritture

---

*Fine report.*
