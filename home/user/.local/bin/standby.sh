#!/bin/bash
# standby.sh — Sospende il sistema in sicurezza (S3 / mem sleep)

# Sincronizza tutto
sync

# Blocca lo schermo (xss-lock si occupa di i3lock, ma per sicurezza richiamiamolo)
( xss-lock -- i3lock -n -c 000000 & ) >/dev/null 2>&1 || true

# Attendi un attimo che il lock sia pronto
sleep 0.3

# Sospendi
systemctl suspend
