#!/usr/bin/env python3
"""Deploy our Vesktop theme tweaks.

Vesktop is a flatpak here and cannot read ~/dotfiles, so a symlink out of the
sandbox would be a dead path for it - the file has to be copied in. It lands in
themes/ next to the generated dank-discord.css and is enabled the same way.
"""

import os
import shutil

SOURCE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vesktop.css")
TARGET = os.path.expanduser("~/.config/vesktop/themes/discord-tweaks.css")

if os.path.exists(SOURCE) and os.path.isdir(os.path.dirname(TARGET)):
    # Vencord watches the file, so only touch it when it actually differs
    if not os.path.exists(TARGET) or open(TARGET).read() != open(SOURCE).read():
        shutil.copyfile(SOURCE, TARGET)
        print(f"vesktop: discord-tweaks.css -> {TARGET}")
