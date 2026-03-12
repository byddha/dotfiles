# Ghostty terminal theme generation
# Receives: $base00-$base0F, $CACHE_DIR, $THEME_NAME

cat > "$CACHE_DIR/ghostty.conf" << EOF
# Base16 theme: $THEME_NAME
foreground = $base05
background = $base00
selection-foreground = $base00
selection-background = $base05
cursor-color = $base05
cursor-text = $base00
palette = 0=$base00
palette = 1=$base08
palette = 2=$base0B
palette = 3=$base0A
palette = 4=$base0D
palette = 5=$base0E
palette = 6=$base0C
palette = 7=$base05
palette = 8=$base03
palette = 9=$base08
palette = 10=$base0B
palette = 11=$base0A
palette = 12=$base0D
palette = 13=$base0E
palette = 14=$base0C
palette = 15=$base07
EOF

# Reload ghostty
pkill -SIGUSR2 ghostty 2>/dev/null || true
