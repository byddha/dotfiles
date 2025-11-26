# Quickshell theme IPC
# Receives: $THEME_NAME

qs ipc call theme setTheme "$THEME_NAME" 2>/dev/null || true
