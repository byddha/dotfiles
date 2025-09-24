#!/bin/bash

CAPACITY=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)
STATUS=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null)

if [ -z "$CAPACITY" ]; then
    echo "  100%"
    exit 0
fi

if [ "$CAPACITY" -ge 80 ]; then
    BAR=" "
elif [ "$CAPACITY" -ge 60 ]; then
    BAR=" "
elif [ "$CAPACITY" -ge 40 ]; then
    BAR=" "
elif [ "$CAPACITY" -ge 20 ]; then
    BAR=" "
else
    BAR=" "
fi

if [ "$STATUS" = "Charging" ]; then
    echo "⚡ ${BAR} ${CAPACITY}%"
else
    echo "${BAR} ${CAPACITY}%"
fi
