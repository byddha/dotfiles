#!/bin/bash

if pgrep openfortivpn > /dev/null; then
    sudo killall openfortivpn
    notify-send "FortiVPN" "Disconnected" -i network-vpn-disconnected
else
    export GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d \')
    PASSWORD=$(zenity --password --title="FortiVPN Authentication")
    
    if [ $? -ne 0 ]; then
        notify-send "FortiVPN" "Connection canceled" -i dialog-error
        exit 1
    fi
    
    if [ -n "$PASSWORD" ]; then
        sudo openfortivpn -p "$PASSWORD" &
        
        notify-send "FortiVPN" "Connecting..." -i network-vpn
    else
        notify-send "FortiVPN" "No password entered" -i dialog-error
    fi
fi
