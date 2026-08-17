# theme-set

Themes come from the DMS registry. `theme-set <id>` resolves the theme, runs it
through the DMS matugen templates, and patches adw-gtk3.

```
theme-set catppuccin --flavor mocha --accent blue
theme-set --list      # themes + their flavors/accents/variants
theme-set --menu      # rows for the walker/elephant picker
theme-set --update    # git pull the registry
```

## Layout

| | |
|---|---|
| `~/.local/share/theme-set/` | bootstrapped on first run: DMS templates + `scripts/`, cloned registry |
| `~/.cache/theme/dms-colors.json` | generated palette, ~50 material roles + 16 ansi slots |
| `~/.cache/theme/state.json` | active theme + mode, watched by the quickshell `ThemeService` |
| `dms-resolve` | theme.json (19 roles) → the ~50 roles matugen wants |
| `*.sh` | our own modules, sourced with `$base00`-`$base0F` exported |

## Enabling another DMS template

DMS ships templates for nvim, zed, firefox, foot, alacritty, emacs and more.
They are all blocked by `SKIP_TEMPLATES` in `theme-set` so they cannot fight the
modules in this directory. To adopt one, e.g. nvim:

1. Delete `nvim` from `SKIP_TEMPLATES`.
2. Run `theme-set <current>`; it writes the file the template declares. Check
   `~/.local/share/theme-set/matugen/configs/neovim.toml` for the output path.
3. Point the app at that file (`colorscheme dms`, an `include`, an `@import`...).
4. Delete our `*.sh` module for that app, if one exists.

`dms matugen check` lists every template and whether the app was detected.

Templates are inert until step 3 — the file just sits there.

## Deliberately not on DMS

| | why |
|---|---|
| `hyprland.sh` | DMS calls `hl.config()` directly, ours returns a table for `appearance.lua`; both would set `general.col.active_border` |
| `zen.sh` | ours covers 56 CSS variables vs their 13, including `about:preferences` and newtab |
| `btop.sh` `konsole.sh` `walker.sh` | DMS has no template for these |

## Gotchas

- `dms matugen generate` exits **2** when the palette is unchanged. Not an error.
- Vesktop is a flatpak here, and the packaged `dms` 1.5.3 cannot write to flatpak
  config dirs (that landed upstream after the release). `~/.config/vesktop/themes`
  is symlinked into `~/.var/app/dev.vencord.Vesktop/config/vesktop/themes` to
  cover it. Drop the symlink once a release ships the fix.
- GTK3 colors live inside `~/.local/share/themes/adw-gtk3*/gtk-3.0/*.css`, between
  the `DMS OVERRIDE` markers. A `@define-color` in `~/.config/gtk-3.0` is not
  enough — adw-gtk3 has literal hex values baked in. `.dms-backup` files hold the
  pristine stylesheets.
- Qt needs `style=Breeze` (or Fusion). Kvantum draws with colors baked into its
  own SVGs and ignores the palette entirely.
- `qt6ct.conf` and `gtk-*/settings.ini` are not in git — `theme-set` creates them.
