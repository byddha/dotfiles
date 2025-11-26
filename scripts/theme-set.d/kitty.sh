# Kitty terminal theme generation
# Receives: $base00-$base0F, $CACHE_DIR, $THEME_NAME

cat > "$CACHE_DIR/kitty.conf" << EOF
# Base16 theme: $THEME_NAME
foreground $base05
background $base00
selection_foreground $base00
selection_background $base05
cursor $base05
cursor_text_color $base00
color0 $base00
color1 $base08
color2 $base0B
color3 $base0A
color4 $base0D
color5 $base0E
color6 $base0C
color7 $base05
color8 $base03
color9 $base08
color10 $base0B
color11 $base0A
color12 $base0D
color13 $base0E
color14 $base0C
color15 $base07
EOF

# Reload kitty
pkill -SIGUSR1 kitty 2>/dev/null || true
