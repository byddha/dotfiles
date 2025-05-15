#!/usr/bin/env bash

dir="$HOME/.config/rofi/"


if [[ $1 == "emoji" ]]; then
    rofimoji --selector-args="-theme ${dir}/emoji.rasi" 
elif [[ $1 == "drun" ]]; then
    rofi -show drun -theme ${dir}/apps.rasi
elif [[ $1 == "clipboard" ]]; then
    rofi -show clipboard -theme ${dir}/clip.rasi
elif [[ $1 == "calc" ]]; then
    rofi -show calc -theme ${dir}/calc.rasi
else
    echo "Invalid argument. Available options are: drun, clipboard, emoji, calc"
    exit 1
fi

