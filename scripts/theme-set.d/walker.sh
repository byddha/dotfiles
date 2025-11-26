# Walker launcher theme generation
# Receives: $base00-$base0F, $CACHE_DIR, $THEME_NAME

cat > "$CACHE_DIR/walker-colors.css" << EOF
/* Base16 theme: $THEME_NAME */
@define-color window_bg_color $base00;
@define-color accent_bg_color $base0D;
@define-color theme_fg_color $base05;
@define-color error_bg_color $base08;
@define-color error_fg_color $base05;
EOF

# Walker auto-reloads CSS changes
