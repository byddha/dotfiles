#!/bin/bash
if nmcli -t -f TYPE,STATE device status | grep -q "wifi:connected"; then
    SSID=$(nmcli -t -f NAME connection show --active | grep -v "lo\|Wired" | head -1)
    SIGNAL=$(nmcli device wifi list --rescan no | grep "^\*" | awk '{print $8}' | head -1)

    if [ -n "$SIGNAL" ] && [ "$SIGNAL" -gt 0 ]; then
        if [ "$SIGNAL" -ge 80 ]; then
            BARS="▰▰▰▰▱"
        elif [ "$SIGNAL" -ge 60 ]; then
            BARS="▰▰▰▱▱"
        elif [ "$SIGNAL" -ge 40 ]; then
            BARS="▰▰▱▱▱"
        elif [ "$SIGNAL" -ge 20 ]; then
            BARS="▰▱▱▱▱"
        else
            BARS="▱▱▱▱▱"
        fi
        echo "  $SSID ${BARS}"
    else
        echo "  $SSID"
    fi
elif ip route get 1 2>/dev/null | grep -q "dev"; then
    echo "󰈀 Wired ▰▰▰▰▰"
else
    echo "󰈂 Offline ▱▱▱▱▱"
fi
