#!/bin/sh
# Read Razer mouse battery via OpenRazer sysfs
# charge_level is 0-255, convert to 0-100
# When multiple entries exist (dongle + USB), pick the highest value
# Output: {"percentage": 0-100, "charging": true/false}

BEST_RAW=0
BEST_DIR=""

for f in $(find /sys/devices -maxdepth 10 -path "*1532*" -name "charge_level" 2>/dev/null); do
    RAW=$(cat "$f" 2>/dev/null) || continue
    if [ "$RAW" -gt "$BEST_RAW" ]; then
        BEST_RAW=$RAW
        BEST_DIR=$(dirname "$f")
    fi
done

[ -z "$BEST_DIR" ] && exit 1
[ "$BEST_RAW" -eq 0 ] && exit 1

CHRG=$(cat "$BEST_DIR/charge_status" 2>/dev/null) || exit 1
LEVEL=$(( BEST_RAW * 100 / 255 ))

if [ "$CHRG" = "1" ]; then
    echo "{\"percentage\":$LEVEL,\"charging\":true}"
else
    echo "{\"percentage\":$LEVEL,\"charging\":false}"
fi
