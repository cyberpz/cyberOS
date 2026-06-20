# Recap sessioni DebianPz

**Data:** 2026-06-20  
**Sessione:** continuazione di DebianPz1

---

## Sessione precedente — DebianPz1

### Spazio e RAM

- **Home RAM aumentata** da 4 GB a 5 GB (`tmpfs /home/user`)
- **Cache spostate su NVMe** via symlink per liberare RAM:
  - `~/.kimi-code/bin`
  - `~/.opencode/bin` e `node_modules`
  - `~/.local/lib/python3.13`
  - `~/.local/share/opencode`
  - `~/.local/share/luakit`
- **Persistenza verificata** e funzionante
- **NVMe** riconosciuta come `nvme0n1`, health OK, ~6% vita consumata

---

## Sessione odierna — continuazione DebianPz1

### 1. Pulizia spazio home RAM

La home si era di nuovo riempita (~4.5 GB / 5 GB). Sono stati spostati su NVMe:

- `~/.npm` (~1.3 GB)
- `~/.gradle` (~1.4 GB)
- `~/.pub-cache` (~180 MB)
- `~/Downloads`
- `~/.config/opencode`

**Risultato:** home scesa a ~2.2 GB / 5 GB, RAM disponibile aumentata.

Creato/aggiornato:

```bash
~/.local/bin/setup-home-cache-links.sh
```

per ricreare automaticamente i symlink al prossimo avvio.

### 2. Estensione Firefox

- Installato **Vimium-FF v2.4.2** nel profilo Firefox attivo
- Creata policy globale in `/usr/lib/firefox-esr/distribution/policies.json`
- Firefox riavviato per attivarla

### 3. Polybar

- **Rimossa la barra on-hover** (`cyber-hover`)
  - commentato `polybar-hover-monitor.sh` in i3 config
  - modificato `~/.local/bin/launch-polybar.sh` per lanciare solo `cyber`
- **Aggiunti titoli dinamici ai workspace** tramite script i3
- **Rimosso il titolo finestra dalla barra principale** perché duplicato nei workspace

### 4. i3 — workspace dinamici

Creato e perfezionato:

```bash
~/.local/bin/i3-dynamic-workspace-names.sh
```

Rinomina automaticamente i workspace in base al titolo della finestra attiva:

```text
1:Alacritty  2:DebianPz2  3:Telegram  5:DomusAPP
```

Se un workspace è vuoto, usa il nome di default (`term`, `web`, `code`, …).

Modificati i binding i3 da `workspace $wsN` a `workspace number N` per funzionare con nomi dinamici.

### 5. Auto-suspend

Installato `xprintidle` e creato:

```bash
~/.local/bin/auto-suspend.sh
```

Sospende il PC quando:

- inattività tastiera/mouse ≥ **30 minuti**
- **load average < 0.5** (nessun processo sta lavorando seriamente)

Aggiunto all’autostart di i3.

### 6. Persistenza

Dopo ogni modifica:

```bash
sudo /usr/local/bin/persist-save
```

così tutte le configurazioni sopravvivono al riavvio.

---

## File principali modificati/creati

```text
~/.config/polybar/config.ini
~/.config/i3/config
~/.local/bin/launch-polybar.sh
~/.local/bin/i3-dynamic-workspace-names.sh
~/.local/bin/setup-home-cache-links.sh
~/.local/bin/auto-suspend.sh
/usr/local/sbin/ram-home.sh
/usr/lib/firefox-esr/distribution/policies.json
```

---

## Stato attuale del sistema

```text
Home RAM:  ~2.2 GB / 5 GB usati
RAM:       ~1.5 GB disponibili
Swap:      ~3.9 GB / 4 GB (sotto pressione)
```

Il freeze notturno è probabilmente dovuto a RAM/swap esauriti. L’auto-suspend mitiga il problema spegnendo il PC quando inattivo e senza processi attivi.
