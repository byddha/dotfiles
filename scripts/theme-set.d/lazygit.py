#!/usr/bin/env python3
"""theme-set module: export the active Neovim palette to Delta's private cache."""

import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile


EXPORT_LUA = r'''
local ok, lazy = pcall(require, "lazy")
if ok then lazy.load({ plugins = { "codediff.nvim" } }) end
local groups = {
  "Normal", "Comment", "String", "Number", "Boolean", "SpecialChar",
  "Keyword", "Type", "StorageClass", "Function", "Identifier", "Operator",
  "Delimiter", "Error", "Title", "LineNr", "Directory", "DiffAdd", "DiffDelete",
  "CodeDiffLineInsert", "CodeDiffLineDelete", "CodeDiffCharInsert", "CodeDiffCharDelete",
  "@keyword", "@string", "@number", "@boolean", "@function", "@type",
  "@variable", "@variable.parameter", "@operator", "@punctuation.delimiter",
}
local result = { background = vim.o.background, name = vim.g.colors_name, groups = {} }
for _, name in ipairs(groups) do
  result.groups[name] = vim.api.nvim_get_hl(0, { name = name, link = false })
end
vim.fn.writefile({ vim.json.encode(result) }, vim.env.THEME_SET_EXPORT_OUTPUT)
'''


def export_palette():
    # Start once per theme switch, never once per diff. Use the real config so
    # colorscheme hooks and CodeDiff highlight overrides are included.
    with tempfile.TemporaryDirectory(prefix="theme-set-nvim-") as tmp:
        root = Path(tmp)
        script = root / "export.lua"
        output = root / "palette.json"
        script.write_text(EXPORT_LUA)
        env = dict(os.environ, THEME_SET_EXPORT_SCRIPT=str(script),
                   THEME_SET_EXPORT_OUTPUT=str(output))
        result = subprocess.run(
            ["nvim", "--headless", "-n", "-i", "NONE",
             "+lua dofile(vim.env.THEME_SET_EXPORT_SCRIPT)", "+qa!"],
            cwd=root, env=env, capture_output=True, text=True, timeout=30,
        )
        if result.returncode or not output.exists():
            raise RuntimeError(f"Neovim palette export failed: {result.stderr.strip()}")
        return json.loads(output.read_text())


def color(palette, names, field="fg", fallback=None):
    for name in names:
        group = palette["groups"].get(name, {})
        # Match what Neovim draws for reverse-video highlight groups.
        key = ("bg" if field == "fg" else "fg") if group.get("reverse") else field
        if key in group:
            return f'#{group[key]:06x}'
    if fallback is not None:
        return fallback
    raise ValueError(f"Neovim theme has no {field} for {', '.join(names)}")


def brighter(value, factor):
    channels = [int(value[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{min(255, int(c * factor)):02x}" for c in channels)


def build_theme(palette):
    foreground = color(palette, ["Normal"])
    background = color(palette, ["Normal"], "bg")
    settings = [{"settings": {"foreground": foreground, "background": background}}]
    # TextMate scopes and Tree-sitter captures differ; share the palette while
    # leaving Delta/Syntect responsible for language parsing.
    scopes = [
        ("comment", ["Comment"]),
        ("string", ["@string", "String"]),
        ("constant.numeric", ["@number", "Number"]),
        ("constant.language", ["@boolean", "Boolean"]),
        ("constant.character.escape", ["SpecialChar"]),
        ("keyword", ["@keyword", "Keyword"]),
        ("storage.type", ["@type", "Type"]),
        ("storage.modifier", ["StorageClass", "Keyword"]),
        ("entity.name.function, support.function", ["@function", "Function"]),
        ("entity.name.type, support.type", ["@type", "Type"]),
        ("variable", ["@variable", "Identifier"]),
        ("variable.parameter", ["@variable.parameter", "Identifier"]),
        ("keyword.operator", ["@operator", "Operator"]),
        ("punctuation", ["@punctuation.delimiter", "Delimiter"]),
        ("invalid", ["Error"]),
        ("markup.heading", ["Title"]),
    ]
    for scope, groups in scopes:
        settings.append({"scope": scope, "settings": {
            "foreground": color(palette, groups, fallback=foreground),
        }})
    return plistlib.dumps({"name": "theme-set-nvim", "settings": settings})


def build_config(palette):
    added = color(palette, ["CodeDiffLineInsert", "DiffAdd"], "bg")
    removed = color(palette, ["CodeDiffLineDelete", "DiffDelete"], "bg")
    factor = 0.92 if palette["background"] == "light" else 1.4
    add_word = color(palette, ["CodeDiffCharInsert"], "bg", brighter(added, factor))
    del_word = color(palette, ["CodeDiffCharDelete"], "bg", brighter(removed, factor))
    foreground = color(palette, ["Normal"])
    muted = color(palette, ["LineNr", "Comment"], fallback=foreground)
    accent = color(palette, ["Directory", "Title"], fallback=foreground)
    # Quote values: Git config treats unquoted # as the start of a comment.
    options = {
        "dark": str(palette["background"] == "dark").lower(),
        "light": str(palette["background"] == "light").lower(),
        "syntax-theme": "theme-set-nvim",
        "true-color": "always",
        "zero-style": "syntax",
        "plus-style": f"syntax {added}",
        "minus-style": f"syntax {removed}",
        "plus-emph-style": f"syntax {add_word}",
        "minus-emph-style": f"syntax {del_word}",
        "line-numbers-zero-style": muted,
        "line-numbers-left-style": muted,
        "line-numbers-right-style": muted,
        "line-numbers-plus-style": color(palette, ["DiffAdd"], fallback=foreground),
        "line-numbers-minus-style": color(palette, ["DiffDelete"], fallback=foreground),
        "file-style": f"{accent} bold",
        "file-decoration-style": f"{muted} ul",
        "hunk-header-style": "file line-number syntax",
        "hunk-header-decoration-style": f"{muted} box",
    }
    return "# Generated by theme-set from Neovim; do not edit.\n[delta]\n" + "".join(
        f"    {key} = {json.dumps(value)}\n" for key, value in options.items()
    )


def main():
    if not shutil.which("delta"):
        return
    if not shutil.which("bat"):
        raise RuntimeError("bat is required to build the Neovim syntax theme for Delta")
    palette = export_palette()
    root = Path(os.environ.get("CACHE_DIR", str(Path.home() / ".cache/theme"))) / "lazygit"
    root.mkdir(parents=True, exist_ok=True)
    # Build and validate separately before replacing the last working palette.
    with tempfile.TemporaryDirectory(prefix=".build-", dir=root) as tmp:
        build = Path(tmp)
        themes = build / "themes"
        themes.mkdir()
        (themes / "theme-set-nvim.tmTheme").write_bytes(build_theme(palette))
        cache = build / "bat"
        subprocess.run(["bat", "cache", "--build", "--source", str(build),
                        "--target", str(cache)], check=True, capture_output=True)
        config = build / "delta.gitconfig"
        config.write_text(build_config(palette))
        # Delta reads bat assets from $XDG_CACHE_HOME/bat (BAT_CACHE_PATH is
        # not honored by Delta). Keep this independent of the user's bat cache.
        env = dict(os.environ, XDG_CACHE_HOME=str(build))
        probe = subprocess.run(
            ["delta", "--config", str(config), "--paging=never"],
            input="diff --git a/test.py b/test.py\n--- a/test.py\n+++ b/test.py\n"
                  "@@ -1 +1 @@\n-for x in range(3):\n+for x in range(5):\n",
            env=env, capture_output=True, text=True, check=True,
        )
        if "theme-set-nvim" not in subprocess.check_output(
            ["delta", "--list-syntax-themes"], env=env, text=True
        ) or "Invalid theme" in probe.stderr:
            raise RuntimeError("Delta could not load the generated Neovim syntax theme")
        target_cache = root / "bat"
        target_cache.mkdir(exist_ok=True)
        for asset in cache.iterdir():
            os.replace(asset, target_cache / asset.name)
        os.replace(themes / "theme-set-nvim.tmTheme", root / "theme-set-nvim.tmTheme")
        os.replace(config, root / "delta.gitconfig")
    print(f"lazygit: imported Neovim theme {palette.get('name') or 'current'} ({palette['background']})")


if __name__ == "__main__":
    main()
