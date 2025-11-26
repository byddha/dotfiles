# Icon theme generation using oomox/themix
# Receives: $base00-$base0F, $THEME_NAME

# Skip if oomox not installed
OOMOX_PAPIRUS="/opt/oomox/plugins/icons_papirus/change_color.sh"
[[ ! -x "$OOMOX_PAPIRUS" ]] && return 0

ICON_THEME="base16-icons"
PRESET_FILE="$CACHE_DIR/oomox-preset"

echo "Generating icons (this takes 10-30s)..."

# Generate oomox preset from base16 colors
cat > "$PRESET_FILE" << EOF
BG=${base00#\#}
FG=${base05#\#}
SEL_BG=${base0D#\#}
ICONS_LIGHT=${base0D#\#}
ICONS_MEDIUM=${base0D#\#}
ICONS_DARK=${base00#\#}
EOF

# Generate Papirus icons
"$OOMOX_PAPIRUS" -o "$ICON_THEME" "$PRESET_FILE" >/dev/null 2>&1

# Set GTK icon theme
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true

# Set Qt icon theme (qt6ct)
QT6CT_CONF="$HOME/.config/qt6ct/qt6ct.conf"
if [[ -f "$QT6CT_CONF" ]]; then
    sed -i "s/^icon_theme=.*/icon_theme=$ICON_THEME/" "$QT6CT_CONF"
fi

echo "Icons generated: $ICON_THEME"

notify-send "Icons Ready" "Generated: $ICON_THEME" -i preferences-desktop-icons 2>/dev/null || true
