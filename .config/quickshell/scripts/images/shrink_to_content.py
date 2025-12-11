#!/usr/bin/env python3
"""
Shrink selection to content bounds.

Usage: shrink_to_content.py <image_path> <x> <y> <width> <height> [threshold]

Output: JSON with new bounds: {"x": int, "y": int, "width": int, "height": int}
"""

import sys
import json
from PIL import Image, ImageChops, ImageStat

def find_content_bounds_fast(region, threshold=30):
    w, h = region.size
    if h < 2 or w < 2:
        return 0, 0, w, h

    sample = min(5, h // 4, w // 4) or 1
    corners = [
        region.crop((0, 0, sample, sample)),
        region.crop((w - sample, 0, w, sample)),
        region.crop((0, h - sample, sample, h)),
        region.crop((w - sample, h - sample, w, h)),
    ]

    # Average color across all corner pixels
    r = g = b = 0
    for corner in corners:
        stat = ImageStat.Stat(corner)
        r += stat.mean[0]
        g += stat.mean[1]
        b += stat.mean[2]
    bg = (int(r / 4), int(g / 4), int(b / 4))

    bg_img = Image.new('RGB', (w, h), bg)
    diff = ImageChops.difference(region.convert('RGB'), bg_img)
    gray = diff.convert('L')
    mask = gray.point(lambda p: 255 if p > threshold else 0)
    bbox = mask.getbbox()

    return bbox if bbox else (0, 0, w, h)

def main():
    if len(sys.argv) < 6:
        print(json.dumps({"error": "Usage: shrink_to_content.py <image> <x> <y> <w> <h> [threshold]"}))
        sys.exit(1)

    x, y, w, h = int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
    threshold = int(sys.argv[6]) if len(sys.argv) > 6 else 30

    try:
        img = Image.open(sys.argv[1])
        region = img.crop((x, y, x + w, y + h))
        left, top, right, bottom = find_content_bounds_fast(region, threshold)

        # Add padding to shrunk edges
        padding = 4
        final_left = max(0, left - padding) if left > 0 else left
        final_top = max(0, top - padding) if top > 0 else top
        final_right = min(w, right + padding) if right < w else right
        final_bottom = min(h, bottom + padding) if bottom < h else bottom

        new_x, new_y = x + final_left, y + final_top
        new_w, new_h = final_right - final_left, final_bottom - final_top

        if new_w < 10: new_w, new_x = w, x
        if new_h < 10: new_h, new_y = h, y

        print(json.dumps({"x": new_x, "y": new_y, "width": new_w, "height": new_h}))

    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    main()
