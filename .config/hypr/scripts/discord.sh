discord_zoom_script="$HOME/dotfiles/.config/hypr/scripts/discord_zoom.js"
cat "$discord_zoom_script" | wl-copy


hyprctl dispatch focuswindow class:vesktop  && \ 
hyprctl dispatch sendshortcut CONTROL SHIFT, I, class:vesktop && \
sleep 1 && \
hyprctl dispatch sendshortcut CONTROL SHIFT, V, initialTitle: Developer Tools && \
sleep 1 && \
hyprctl dispatch sendshortcut , RETURN, initialTitle: Developer Tools
sleep 1 && \
hyprctl dispatch closewindow initialTitle: Developer Tools





