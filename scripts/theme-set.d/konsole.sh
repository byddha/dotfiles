# Konsole terminal colorscheme generation
# Receives: $base00-$base0F, $CACHE_DIR, $THEME_NAME

KONSOLE_DIR="$HOME/.local/share/konsole"
mkdir -p "$KONSOLE_DIR"

# Convert hex (#RRGGBB) to RGB (R,G,B)
hex_to_rgb() {
    local hex="${1#\#}"
    printf "%d,%d,%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# Generate color section with normal, faint, and intense (bright) variants
# $1 = section name, $2 = normal hex, $3 = intense/bright hex
color_section() {
    local name="$1" hex="$2" intense_hex="$3"
    cat << EOF
[$name]
Color=$(hex_to_rgb "$hex")

[${name}Faint]
Color=$(hex_to_rgb "$hex")

[${name}Intense]
Color=$(hex_to_rgb "$intense_hex")

EOF
}

{
    # Background/Foreground (intense uses same color)
    color_section "Background" "$base00" "$base00"
    color_section "Foreground" "$base05" "$base07"
    # ANSI colors: normal = color0-7, intense = color8-15 (bright)
    # Matching kitty.sh mapping exactly
    color_section "Color0" "$base00" "$base03"  # Black / Bright Black
    color_section "Color1" "$base08" "$base08"  # Red / Bright Red
    color_section "Color2" "$base0B" "$base0B"  # Green / Bright Green
    color_section "Color3" "$base0A" "$base0A"  # Yellow / Bright Yellow
    color_section "Color4" "$base0D" "$base0D"  # Blue / Bright Blue
    color_section "Color5" "$base0E" "$base0E"  # Magenta / Bright Magenta
    color_section "Color6" "$base0C" "$base0C"  # Cyan / Bright Cyan
    color_section "Color7" "$base05" "$base07"  # White / Bright White
    echo "[General]"
    echo "Description=Base16: $THEME_NAME"
    echo "Opacity=1"
} > "$KONSOLE_DIR/base16.colorscheme"
