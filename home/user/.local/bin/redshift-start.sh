#!/bin/bash
# Avvia redshift con i parametri di DebianPz
pkill -9 -x redshift 2>/dev/null || true
redshift -l 41.9028:12.4964 -t 6500:3500 -g 0.8 -m randr >/dev/null 2>&1 &
