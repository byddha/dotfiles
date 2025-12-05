#!/usr/bin/env python3
"""
Resolve XDG icon names to file paths using GTK's icon theme.
Usage: resolve_icon.py <icon_name> [size]
"""
import sys
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

def resolve_icon(icon_name, size=64):
    if not icon_name:
        return ""

    # If already a path, return it
    if icon_name.startswith('/') or icon_name.startswith('file://'):
        return icon_name

    theme = Gtk.IconTheme.get_default()
    icon_info = theme.lookup_icon(icon_name, size, 0)

    if icon_info:
        return icon_info.get_filename()
    return ""

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("")
        sys.exit(0)

    icon_name = sys.argv[1]
    size = int(sys.argv[2]) if len(sys.argv) > 2 else 64

    result = resolve_icon(icon_name, size)
    print(result)
