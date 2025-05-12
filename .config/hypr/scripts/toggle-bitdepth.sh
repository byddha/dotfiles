#!/usr/bin/env bash

CONFIG="$HOME/dotfiles/.config/hypr/monitors.conf"

mode=$(grep -Po '^monitor=DP-3.*bitdepth,\K[0-9]+' "$CONFIG")
if [[ -z "$mode" ]]; then
  echo "Failed to detect current bit depth for DP-3 in $CONFIG" >&2
  exit 1
fi

if [[ "$mode" -eq 10 ]]; then
  new=8
else
  new=10
fi

if ! zenity --question \
      --title="Bit-depth change" \
      --text="Current bit depth: ${mode}-bit\nChange to: ${new}-bit?"; then
  echo "Operation canceled by user."
  exit 0
fi

if sed -i "/^monitor=DP-3/ s/bitdepth,${mode}/bitdepth,${new}/" "$CONFIG"; then
  echo "Successfully updated DP-3 bit depth to ${new}-bit in $CONFIG." 
else
  echo "Failed to update $CONFIG." >&2
  exit 1
fi
