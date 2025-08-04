#!/usr/bin/env bash
# TLDLR: I don't want borders when there is only one window in a workspace
# Started from https://github.com/devadathanmb/hyprland-smart-borders/blob/main/dynamic-borders.sh
# Refactored it to my liking and fixed some issues (particularly with applications that spawn new windows for context menus)

source ~/dotfiles/.config/hypr/scripts/ipc_helper.sh


set_border() {
    local address="$1"
    local noborder_state="$2"
    hyprctl dispatch setprop address:"$address" noborder "$noborder_state"
}

# -----------------------------------------------------------------------------
# Updates borders for windows within a specified workspace.
# It ignores pop-up/context-menu windows (identified as floating with no title)
# both when counting windows and when setting borders.
#
# For all *other* (non-ignored) windows, it applies these rules:
#   - Floating windows always have borders (noborder 0).
#   - Tiled windows have no borders (noborder 1) if they are the *only* non-ignored window.
#   - Tiled windows have borders (noborder 0) if multiple non-ignored windows exist.
#
# Arguments:
#   $1: Workspace ID or "special".
# -----------------------------------------------------------------------------
update_workspace_borders() {
    local ws_ref="$1"
    local ws_id

    # Convert "special" workspace name to its numeric ID (-99)
    if [[ "$ws_ref" == "special" ]]; then
        ws_id=-99
    else
        ws_id="$ws_ref"
    fi

    # Get all windows with necessary info {address, floating, title}
    local windows_json
    windows_json=$(hyprctl clients -j | jq --argjson id "$ws_id" \
        '[.[] | select(.workspace.id == $id) | {address: .address, floating: .floating, title: .title}]')

    # Calculate the count, *ignoring* floating windows with empty titles
    local window_count
    window_count=$(echo "$windows_json" | jq '[.[] | select(.floating == false or (.floating == true and .title != ""))] | length')

    # Process each window
    echo "$windows_json" | jq -c '.[]' | while read -r window_info; do
        local address
        address=$(echo "$window_info" | jq -r '.address')
        local is_floating
        is_floating=$(echo "$window_info" | jq -r '.floating')
        local title
        title=$(echo "$window_info" | jq -r '.title')

        # Check if it's a context menu/popup (floating + empty title)
        if [[ "$is_floating" == "true" && -z "$title" ]]; then
            continue
        fi

        # Process *real* windows
        if [[ "$is_floating" == "true" ]]; then
            if [[ "$window_count" -eq 1 ]]; then
                set_border "$address" 1
            else
                set_border "$address" 0
            fi
        elif [[ "$window_count" -eq 1 ]]; then
            # Single tiled window gets no border (noborder 1)
            set_border "$address" 1
        else
            # Multiple tiled windows get borders (noborder 0)
            set_border "$address" 0
        fi
    done
}


on_openwindow() {
    local workspace_id="$2"
    update_workspace_borders "$workspace_id"
}


on_movewindow() {
    local workspace_id="$2"

    update_workspace_borders "$workspace_id"

    local single_window_workspaces
    single_window_workspaces=$(hyprctl workspaces -j | jq -r '.[] | select(.windows == 1) | .id')

    local dest_ws_id="$2"
     if [[ "$dest_ws_id" == "special" ]]; then
        dest_ws_id=-99
    fi

    for ws in $single_window_workspaces; do
        if [[ "$ws" -ne "$dest_ws_id" ]]; then
             update_workspace_borders "$ws"
        fi
    done
}

on_closewindow() {
    local active_ws_id
    active_ws_id=$(hyprctl activeworkspace -j | jq '.id')
    update_workspace_borders "$active_ws_id"
}

on_changefloatingmode() {
    local address="0x$1"
    local workspace_id
    workspace_id=$(hyprctl clients -j | jq --arg addr "$address" \
        '.[] | select(.address == $addr) | .workspace.id')

    if [[ -n "$workspace_id" && "$workspace_id" != "null" ]]; then
        update_workspace_borders "$workspace_id"
    fi
}

ipc_listen
