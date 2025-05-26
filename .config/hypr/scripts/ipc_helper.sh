#!/usr/bin/env bash

ipc_handler() {
    local line="$1"
    [[ "$line" != *'>>'* ]] && return 0

    local event="${line%%>>*}"
    local data="${line#*>>}"

    IFS=',' read -r -a parts <<< "$data"
    local handler="on_${event}"
    if declare -f "$handler" &>/dev/null; then
        "$handler" "${parts[@]}"
    fi
}

ipc_listen() {
    local sock="${1:-$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock}"

    socat -U - UNIX-CONNECT:"$sock" \
        | while IFS= read -r line; do
            ipc_handler "$line"
        done
}
