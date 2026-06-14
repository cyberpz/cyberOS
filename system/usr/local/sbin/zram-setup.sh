#!/bin/bash
# Configura ZRAM come swap compresso, dimensione = 30% RAM max 4GB
set -e

ALGO=zstd
TOTAL_KB=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
SIZE_KB=$(( TOTAL_KB * 60 / 100 ))
MAX_KB=$(( 4 * 1024 * 1024 ))   # 4 GiB
[ "$SIZE_KB" -gt "$MAX_KB" ] && SIZE_KB=$MAX_KB

case "$1" in
  start)
    if [ -b /dev/zram0 ] && swapon --show=NAME | grep -q '^/dev/zram0$'; then
      echo "zram0 already active"
      exit 0
    fi
    modprobe zram
    zramctl /dev/zram0 --algorithm "$ALGO" --size "${SIZE_KB}K"
    mkswap /dev/zram0 >/dev/null
    swapon /dev/zram0 -p 100
    ;;
  stop)
    swapoff /dev/zram0 2>/dev/null || true
    zramctl --reset /dev/zram0 2>/dev/null || true
    rmmod zram 2>/dev/null || true
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
