discord_zoom_script="$HOME/dotfiles/.config/hypr/scripts/discord_zoom.js"
cat "$discord_zoom_script" | wl-copy


hyprctl dispatch 'hl.dsp.focus({ window = "class:vesktop" })' && \
hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "I", window = "class:vesktop" })' && \
sleep 1 && \
hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "V", window = "initialtitle:Developer Tools" })' && \
sleep 1 && \
hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "", key = "RETURN", window = "initialtitle:Developer Tools" })'
sleep 1 && \
hyprctl dispatch 'hl.dsp.window.close("initialtitle:Developer Tools")'



