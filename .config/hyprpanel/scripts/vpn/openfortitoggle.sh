#!/bin/bash

if pgrep openfortivpn > /dev/null; then
    sudo killall openfortivpn
    notify-send -e "FortiVPN" "Disconnected" -i network-vpn-disconnected
else
    export GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d \')
    PASSWORD=$(zenity --password --title="FortiVPN Authentication")
    
    if [ $? -ne 0 ]; then
        notify-send -e "FortiVPN" "Connection canceled" -i dialog-error
        exit 1
    fi
    
    if [ -n "$PASSWORD" ]; then
        sudo openfortivpn --set-dns=1 -p "$PASSWORD" &
        
        notify-send -e "FortiVPN" "Connecting..." -i network-vpn
    else
        notify-send -e "FortiVPN" "No password entered" -i dialog-error
    fi
fi
