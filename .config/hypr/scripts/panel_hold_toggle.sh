#!/bin/bash

PANEL_NAME="bar-0"
SLEEP_DURATION=0.5
PIDFILE="/tmp/panel_hold_toggle.pid"
STATEFILE="/tmp/panel_hold_toggle.state"

start_hold_timer() {
  setsid bash -c "
    sleep $SLEEP_DURATION
    hyprpanel toggleWindow \"$PANEL_NAME\"
    echo shown > \"$STATEFILE\"
  " &

  echo $! > "$PIDFILE"
}

stop_hold_timer() {
  if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    kill -TERM -"$PID" 2>/dev/null
    rm -f "$PIDFILE"
  fi

  if [ -f "$STATEFILE" ]; then
    hyprpanel toggleWindow "$PANEL_NAME"
    rm -f "$STATEFILE"
  fi
}

case "$1" in
  start)
    start_hold_timer
    ;;
  stop)
    stop_hold_timer
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
