# btop system monitor theme generation
# Receives: $base00-$base0F, $THEME_NAME

mkdir -p "$HOME/.config/btop/themes"
cat > "$HOME/.config/btop/themes/base16.theme" << EOF
# Base16 theme: $THEME_NAME

# Main background
theme[main_bg]="$base00"

# Main text color
theme[main_fg]="$base05"

# Title color for boxes
theme[title]="$base0D"

# Highlight color for keyboard shortcuts
theme[hi_fg]="$base09"

# Background color of selected items
theme[selected_bg]="$base02"

# Foreground color of selected items
theme[selected_fg]="$base05"

# Color of inactive/disabled text
theme[inactive_fg]="$base03"

# Color of text appearing on top of graphs
theme[graph_text]="$base05"

# Misc colors for processes box
theme[proc_misc]="$base0C"

# Cpu box outline color
theme[cpu_box]="$base08"

# Memory/disks box outline color
theme[mem_box]="$base0B"

# Net up/down box outline color
theme[net_box]="$base0E"

# Processes box outline color
theme[proc_box]="$base0D"

# Box divider line and small boxes line color
theme[div_line]="$base03"

# Gradient colors for cpu graph (low to high)
theme[cpu_start]="$base0B"
theme[cpu_mid]="$base0A"
theme[cpu_end]="$base08"

# Memory graph gradient
theme[mem_start]="$base0D"
theme[mem_mid]="$base0E"
theme[mem_end]="$base08"

# Download/upload graph gradients
theme[download_start]="$base0C"
theme[download_mid]="$base0D"
theme[download_end]="$base0E"
theme[upload_start]="$base0B"
theme[upload_mid]="$base0A"
theme[upload_end]="$base09"

# Process graph gradient
theme[process_start]="$base0D"
theme[process_mid]="$base0C"
theme[process_end]="$base0B"
EOF

# Reload btop
pkill -SIGUSR2 btop 2>/dev/null || true
