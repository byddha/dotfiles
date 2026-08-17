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

DMS ships templates for zed, firefox, foot, alacritty, emacs and more. They are
blocked by `SKIP_TEMPLATES` in `theme-set` so they cannot fight the modules in
this directory. To adopt one:

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

## If base46 does not stick

The nvim template replaces the whole colorscheme with a base46 theme tinted
towards the accent. If those themes are worse than plain `rebelot/kanagawa.nvim`,
the lighter alternative is to keep real kanagawa and override only the surfaces
and the accent, leaving its syntax palette alone.

Kanagawa exposes a semantic map — `ui.bg`, `ui.bg_dim`, `ui.bg_m{1,2,3}`,
`ui.bg_p{1,2}`, `ui.bg_gutter`, `ui.fg`, `ui.fg_dim`, `ui.bg_visual`,
`ui.bg_search`, `ui.pmenu.*`, `ui.float.*`, 18 `syn.*` slots, `diag.*`, `vcs.*`,
`diff.*` — settable via `colors.theme.all = { ... }`, which covers wave, dragon
and lotus at once. Worth mapping:

```
ui.bg    <- background            syn.fun      <- primary
ui.bg_p1 <- surface_container     ui.bg_visual <- primary_container
ui.bg_p2 <- surface_container_high
ui.fg    <- on_surface
```

Read them from `~/.cache/theme/dms-colors.json` (`colors.<mode>`), mode from
`state.json`. Three things found in the plugin source that are not in its README:

- `setup()` deep-extends into the live config, so it can be called again at
  runtime; `load()` then re-applies. No restart needed.
- `load()` does **not** fire the `ColorScheme` autocmd — kanagawa's own reload
  command emits it separately. Without that, heirline will not pick up the new
  colors. Emit `nvim_exec_autocmds("ColorScheme", { modeline = false })`.
- `compile` must stay `false`. With compilation on, changes need
  `:KanagawaCompile`, which kills any hot reload.

Watch `dms-colors.json` with `uv.new_fs_event` to re-apply on theme switch.

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
- The nvim template is the odd one out: it does not generate a palette. It needs
  the `AvengeMedia/base46` plugin, takes one of its builtin themes (`kanagawa`
  here) and tints it towards the DMS accent. Which base theme and how strongly is
  in `~/.config/DankMaterialShell/settings.json` under
  `matugenTemplateNeovimSettings`. It also shells out to `dms ipc call theme
  getMode`, which fails silently without the DMS shell running — light/dark comes
  from `vim.o.background` instead.
