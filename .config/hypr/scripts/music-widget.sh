#!/bin/bash

STATUS=$(playerctl status 2>/dev/null)

if [ "$STATUS" != "Playing" ] && [ "$STATUS" != "Paused" ]; then
    echo ""
    echo ""
    echo "♫ No Music"
    exit 0
fi

ARTIST=$(playerctl metadata artist 2>/dev/null)
TITLE=$(playerctl metadata title 2>/dev/null)
POSITION=$(playerctl position 2>/dev/null)
DURATION=$(playerctl metadata mpris:length 2>/dev/null)

if [ -n "$POSITION" ] && [ -n "$DURATION" ] && [ "$DURATION" -gt 0 ] 2>/dev/null; then
    POS_SEC=$(echo "$POSITION" | awk '{print int($1)}')
    DUR_SEC=$(echo "$DURATION" | awk '{print int($1/1000000)}')

    if [ "$DUR_SEC" -gt 0 ] 2>/dev/null; then
        PROGRESS=$((POS_SEC * 10 / DUR_SEC))
        if [ "$PROGRESS" -gt 10 ]; then
            PROGRESS=10
        fi

        BAR=""
        for i in {1..10}; do
            if [ $i -le $PROGRESS ] 2>/dev/null; then
                BAR="${BAR}═"
            else
                BAR="${BAR}─"
            fi
        done

        POS_MIN=$((POS_SEC / 60))
        POS_SEC_REMAIN=$((POS_SEC % 60))
        DUR_MIN=$((DUR_SEC / 60))
        DUR_SEC_REMAIN=$((DUR_SEC % 60))

        PROGRESS_LINE=$(printf "[%s] %d:%02d/%d:%02d" "$BAR" "$POS_MIN" "$POS_SEC_REMAIN" "$DUR_MIN" "$DUR_SEC_REMAIN")
    else
        PROGRESS_LINE="[──────────] --:--/--:--"
    fi
else
    PROGRESS_LINE="[──────────] --:--/--:--"
fi

if [ -n "$ARTIST" ] && [ -n "$TITLE" ]; then
    echo "Artist: $ARTIST"
    echo "Song: $TITLE"
else
    echo ""
    echo ""
fi

if [ "$STATUS" = "Playing" ]; then
    echo "♫ $PROGRESS_LINE"
elif [ "$STATUS" = "Paused" ]; then
    echo "⏸ $PROGRESS_LINE"
fi
