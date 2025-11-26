# Kvantum theme generation using pywal16-libadwaita templates
# Receives: $base00-$base0F, $THEME_NAME

KVANTUM_DIR="$HOME/.config/Kvantum"
TEMPLATE_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/templates/kvantum"

# Skip if kvantum not installed
command -v kvantummanager &>/dev/null || return 0

# Skip if templates not found
[[ ! -f "$TEMPLATE_DIR/base16.kvconfig.template" ]] && return 0

mkdir -p "$KVANTUM_DIR/base16"

# Process templates using Python
python3 << EOF
import colorsys
import re
import os

def hex_to_hls(hex_color):
    """Convert hex to HLS"""
    hex_color = hex_color.lstrip('#')
    r, g, b = tuple(int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4))
    return colorsys.rgb_to_hls(r, g, b)

def hls_to_hex(h, l, s):
    """Convert HLS back to hex"""
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return '#{:02x}{:02x}{:02x}'.format(int(r*255), int(g*255), int(b*255))

def lighten(hex_color, percent):
    """Lighten a color by percent - returns WITHOUT # (template has it)"""
    h, l, s = hex_to_hls(hex_color)
    l = min(1, l + percent/100)
    return hls_to_hex(h, l, s).lstrip('#')

def darken(hex_color, percent):
    """Darken a color by percent - returns WITHOUT # (template has it)"""
    h, l, s = hex_to_hls(hex_color)
    l = max(0, l - percent/100)
    return hls_to_hex(h, l, s).lstrip('#')

# Base16 colors from environment
colors = {
    'base00': "$base00",
    'base01': "$base01",
    'base02': "$base02",
    'base03': "$base03",
    'base04': "$base04",
    'base05': "$base05",
    'base06': "$base06",
    'base07': "$base07",
    'base08': "$base08",
    'base09': "$base09",
    'base0A': "$base0A",
    'base0B': "$base0B",
    'base0C': "$base0C",
    'base0D': "$base0D",
    'base0E': "$base0E",
    'base0F': "$base0F",
}

# Pywal to Base16 mapping (ANSI terminal colors)
pywal_map = {
    'color0': colors['base00'],   # Black (background)
    'color1': colors['base08'],   # Red
    'color2': colors['base0B'],   # Green
    'color3': colors['base0A'],   # Yellow
    'color4': colors['base0D'],   # Blue
    'color5': colors['base0E'],   # Magenta
    'color6': colors['base0C'],   # Cyan
    'color7': colors['base05'],   # White (foreground)
    'color8': colors['base03'],   # Bright black (comments)
    'color9': colors['base08'],   # Bright red
    'color10': colors['base0B'],  # Bright green
    'color11': colors['base0A'],  # Bright yellow
    'color12': colors['base0D'],  # Bright blue
    'color13': colors['base0E'],  # Bright magenta
    'color14': colors['base0C'],  # Bright cyan
    'color15': colors['base07'],  # Bright white
    'background': colors['base00'],
    'foreground': colors['base05'],
}

def replace_placeholder(match):
    """Replace a pywal placeholder with the corresponding color"""
    placeholder = match.group(1)

    # Check for color manipulation: {colorN.lighten(X%)} or {colorN.darken(X%)}
    manip_match = re.match(r'(\w+)\.(lighten|darken)\((\d+)%\)', placeholder)
    if manip_match:
        color_name = manip_match.group(1)
        operation = manip_match.group(2)
        percent = int(manip_match.group(3))

        if color_name in pywal_map:
            base_color = pywal_map[color_name]
            if operation == 'lighten':
                return lighten(base_color, percent)
            else:
                return darken(base_color, percent)

    # Direct color replacement
    if placeholder in pywal_map:
        return pywal_map[placeholder]

    # Return original if no match (shouldn't happen)
    return match.group(0)

def process_template(template_path, output_path):
    """Process a template file and write output"""
    with open(template_path, 'r') as f:
        content = f.read()

    # Replace all {placeholder} patterns
    result = re.sub(r'\{([^}]+)\}', replace_placeholder, content)

    with open(output_path, 'w') as f:
        f.write(result)

# Process templates
template_dir = "$TEMPLATE_DIR"
output_dir = "$KVANTUM_DIR/base16"

process_template(f"{template_dir}/base16.kvconfig.template", f"{output_dir}/base16.kvconfig")
process_template(f"{template_dir}/base16.svg.template", f"{output_dir}/base16.svg")

print(f"Generated Kvantum theme: base16")
EOF

# Update kvantum.kvconfig to use base16 theme
cat > "$KVANTUM_DIR/kvantum.kvconfig" << EOF
[General]
theme=base16
EOF

