#!/bin/bash
# Generate square color palette icons for each base16 colorscheme
# Creates a 4x4 grid of all 16 base colors

BASE16_DIR="/home/bida/.config/base16"
BLOCK_SIZE=16  # Each color block is 16x16, total icon is 64x64

for yaml in "$BASE16_DIR"/*.yaml; do
    name=$(basename "$yaml" .yaml)
    icon="$BASE16_DIR/$name.png"

    # Extract all 16 base colors
    base00=$(grep 'base00:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base01=$(grep 'base01:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base02=$(grep 'base02:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base03=$(grep 'base03:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base04=$(grep 'base04:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base05=$(grep 'base05:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base06=$(grep 'base06:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base07=$(grep 'base07:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base08=$(grep 'base08:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base09=$(grep 'base09:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base0A=$(grep 'base0A:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base0B=$(grep 'base0B:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base0C=$(grep 'base0C:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base0D=$(grep 'base0D:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base0E=$(grep 'base0E:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)
    base0F=$(grep 'base0F:' "$yaml" | grep -oP '#[0-9a-fA-F]{6}' | head -1)

    [[ -z "$base00" ]] && continue

    # Create 4 rows, then stack them vertically
    # Row 1: base00-03 (backgrounds)
    # Row 2: base04-07 (foregrounds)
    # Row 3: base08-0B (red, orange, yellow, green)
    # Row 4: base0C-0F (cyan, blue, magenta, brown)

    magick \( -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base00" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base01" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base02" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base03" \
              +append \) \
           \( -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base04" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base05" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base06" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base07" \
              +append \) \
           \( -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base08" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base09" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base0A" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base0B" \
              +append \) \
           \( -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base0C" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base0D" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base0E" \
              -size ${BLOCK_SIZE}x${BLOCK_SIZE} xc:"$base0F" \
              +append \) \
           -append "$icon"

    echo "Generated: $icon"
done

echo "Done!"
