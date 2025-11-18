#!/bin/bash

if pgrep -x wf-recorder > /dev/null; then
    pkill -x wf-recorder
    exit 0
fi

monitors=$(hyprctl monitors -j | jq -r '.[] | .name' | paste -sd '|')

export GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d \')

selection=$(zenity --forms \
    --title="Recording Settings" \
    --add-combo="Monitor" --combo-values="$monitors" \
    --add-combo="Audio" --combo-values="Off|On" \
    --separator="|")

if [ $? -ne 0 ]; then
    exit 1
fi

output_selection=$(echo "$selection" | cut -d'|' -f1)
audio_choice=$(echo "$selection" | cut -d'|' -f2)

mkdir -p ~/Videos/Screencasts

timestamp=$(date +%Y-%m-%d_%H-%M-%S)
output_file="$HOME/Videos/Screencasts/recording_${timestamp}.mp4"

audio_flags=()

if [[ "$audio_choice" == "On" ]]; then
    audio_flags+=(--audio)
fi

wf-recorder -c h264_vaapi -o "$output_selection" "${audio_flags[@]}" -f "$output_file"

{
    action=$(notify-send "Recording Saved" "$output_file" --icon=video-x-generic --action="play=Play" --action="open=Open Folder" --wait)
    if [[ "$action" == "play" ]]; then
        xdg-open "$output_file"
    elif [[ "$action" == "open" ]]; then
        xdg-open "$(dirname "$output_file")"
    fi
} &
