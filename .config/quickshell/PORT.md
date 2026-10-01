# bidshell on KWin: what the shell needs, what KWin gives

Checked on bidaLAPTOP: Plasma / KWin 6.7.5, Quickshell 0.3.1 (e3d52a7), one screen eDP-1 at scale 1.5.

How it was checked:
- `wayland-info`: the globals KWin gives an ordinary client.
- `strings /usr/bin/quickshell`: the protocols Quickshell can bind.
- `qdbus6 org.kde.KWin`: the D-Bus API.
- Small qs configs and KWin scripts, run from the session scratchpad and closed afterwards. Plasma and KWin were never restarted.

DankMaterialShell is not on this machine, so I could not check how it abstracts these things. As far as I know it does not support KWin either.

## Protocols

Quickshell can bind these protocols, and KWin 6.7.5 advertises them:
- `zwlr_layer_shell_v1`
- `zwp_idle_inhibit_manager_v1`
- `ext_idle_notifier_v1`
- `zwp_keyboard_shortcuts_inhibit_manager_v1`
- `ext_background_effect_manager_v1`
- `zwp_linux_dmabuf_v1`

`ext_data_control_manager_v1` is also there, which is what wl-copy uses.

Quickshell can bind these, but KWin does not advertise them:
- `zwlr_foreign_toplevel_manager_v1` and `ext_foreign_toplevel_list_v1`: ToplevelManager.
- `zwlr_screencopy_manager_v1` and `ext_image_copy_capture_manager_v1`: ScreencopyView.
- `hyprland_toplevel_export_*`: window previews.
- `ext_workspace_manager_v1`: Quickshell.WindowManager.
- `ext_session_lock_manager_v1`
- `hyprland_focus_grab_v1`
- `hyprland_global_shortcuts_v1`
- `zwp_virtual_keyboard`: needed by wtype.

KWin has its own protocols for some of these: `org_kde_plasma_window_management` and `zkde_screencast_unstable_v1`. It only gives them to clients that a `.desktop` file allows, and Quickshell does not implement them anyway.

## 1. Dependencies

Verdicts:
- **works**: the same code runs on KWin.
- **other API**: a KWin backend has to provide it another way.
- **impossible**: neither Quickshell nor KWin offers it today.

Each verdict is marked **V** (verified on the laptop) or **A** (assumed).

| Where | What it uses | KWin 6.7.5 offers | Verdict |
|---|---|---|---|
| Services/Compositor.qml:17-28 | Picks the backend from `NIRI_SOCKET` / `HYPRLAND_INSTANCE_SIGNATURE`. With neither set, it quits. | `XDG_CURRENT_DESKTOP=KDE`, D-Bus name `org.kde.KWin` | other API (V) |
| Services/Compositor.qml:40-41, Modules/Bar/ActiveWindowButton.qml:10, Services/UI/Notifications.qml:498-503 | ToplevelManager.activeToplevel (title, appId) | No foreign-toplevel protocol: the probe saw 0 toplevels and `activeToplevel` was null. A KWin script has `workspace.activeWindow` and `windowActivated`, and each window's `captionChanged`. | other API (V) |
| HyprlandBackend.qml:19, :39, :192-216 (Hyprland singleton, rawEvent) | Lists of windows, workspaces and monitors, plus change events | A KWin script has `workspace.windowList()`, which gives `internalId`, `resourceClass`, `caption`, `frameGeometry`, `desktops`, `output`, `fullScreen` and `minimized`. It has signals for windows added and removed, desktop changes, screen changes and per-window changes. The script pushes JSON to a D-Bus name with `callDBus`. The round trip works. | other API (V) |
| HyprlandBackend.qml:220-234 (Hyprland.dispatch) | Switch workspace, focus window, log out | Switching works over D-Bus: `org.kde.KWin.setCurrentDesktop(int)`, or the `VirtualDesktopManager.current` property. Focusing a window needs a one-shot script setting `workspace.activeWindow = w`, which is how kdotool does it. Logging out is `org.kde.Shutdown.logout()`, or `org.kde.LogoutPrompt.promptLogout()`. | other API (focus: A; switch and logout methods exist: V) |
| HyprlandBackend.qml:132-154 (`hyprctl cursorpos`) | Cursor position, used by the region selector | KWin script `workspace.cursorPos` (read back over D-Bus) | other API (V) |
| HyprlandBackend.qml:14, and the `focusedMonitorName` users in Sidebar.qml:19, GameLauncher.qml:19, OSD.qml:62, ShutdownReminder.qml:46, Notifications.qml:44, HyprWhichKey.qml:24, SelectionWindow.qml:27 | The focused monitor | D-Bus `org.kde.KWin.activeOutputName()` returned `eDP-1`. A script can read `workspace.activeScreen`, but has no change signal for it, so it has to follow `windowActivated` and `cursorPosChanged`. | other API (V) |
| HyprlandBackend.qml:107-125, Config/BarLayout.qml:72, Modules/Bar/BarAppIcon.qml:14 | Monitor geometry and scale | Script `workspace.screens`: geometry is right, scale is 1.5. Quickshell's `devicePixelRatio` is 2 there, so the scale must come from KWin and not from QScreen. | other API (V) |
| Workspaces.qml:19-35, Config `monitors.<model>.workspaces` | Workspace numbers for each monitor | One shared set of virtual desktops: 3 here, with UUID ids, `x11DesktopNumber` 1..n, and names. Since Plasma 6.7 each screen can show its own current desktop. See [Desktops per screen](#desktops-per-screen). | other API (V, except per-screen independence: A) |
| Workspaces.qml:26, Hdr.qml:32 | `screen.model` as a config key | Hyprland gives the bare model ("MO34WQC2"). KWin's `QScreen.model` is `eDP-1-ATNA40HQ01-0`, with the connector and the serial in the string. The KWin script's `screen.model` gives the bare model. | other API: the key comes from the facade (refactor step 4) (V) |
| WorkspaceMap.qml:24-28, SelectionWindow.qml:81-99 | Window rectangles per workspace (`at`, `size`, floating, fullscreen) | Script `frameGeometry`, in global logical coordinates like Hyprland's. There is no floating/tiled flag. | other API (V) |
| WorkspaceMap.qml:151-156, HyprlandBackend.qml:93 | ScreencopyView of a toplevel: live window previews | Quickshell only captures through hyprland-toplevel-export, ext-image-copy-capture or wlr-screencopy, and KWin has none of them. `ScreenShot2.CaptureWindow` refused with "NoAuthorized: not authorized to take a screenshot". Decided: no ScreenShot2 authorization. | not provided on KWin: `windowPreviewSource` is "", and the map shows icons (decided) |
| SelectionWindow.qml:575 | ScreencopyView of a screen: the frozen background of the region selector | The probe warned "Capture source set to non captureable object". `spectacle -b -n -f -o file.png` worked, and an Image could load that file. | other API: a spectacle still behind `ScreenSnapshot` (V) |
| SelectionWindow.qml:43 | `specialWorkspace` | Not a KWin concept | not needed on KWin (V) |
| Components/FocusGrab.qml:1-3, Popout.qml:81,91, GameLauncher.qml:35-46 | HyprlandFocusGrab, so a click outside closes popouts | No focus-grab protocol. On KWin popouts take the Niri path instead: a fullscreen transparent layer with `Exclusive` keyboard focus. Exclusive focus works: the probe's item had `activeFocus` set. | works via the existing Niri path (V) |
| BarExclusion.qml:15-18 | Layer shell with an exclusive zone | A 30 px exclusive zone moved KWin's maximize area to y=30, and a maximized ghostty moved below it. | works (V) |
| BarWindow, Popout, OSD, Notifications, Sidebar, etc. | Layer shell: Top and Overlay layers, namespace, margins, keyboard focus None / OnDemand / Exclusive | `zwlr_layer_shell_v1` v5. The probe surfaces mapped. A layer with `OnDemand` focus was reported `active` by KWin right after it mapped. | works (V); OnDemand behaviour needs a look (A) |
| Services/System/Idle.qml:23 | IdleInhibitor | `zwp_idle_inhibit_manager_v1`: bound without errors | works (protocol V, effect A) |
| HyprlandBackend.qml:41-62, Compositor.qml:96-98, and the users of `keysFor()` | Keys of described binds ("Super Q") | kglobalaccel D-Bus `/component/<name>` `allShortcutInfos()` returned 181 kwin shortcuts with friendly names and Qt key codes. The codes have to be turned into labels. | other API (V) |
| Modules/HyprWhichKey, Services/Hyprland/HyprWhichKeyService.qml | Which-key overlay for Hyprland submaps | KWin has no submaps. HyprWhichKey stays Hyprland-only and is simply absent on KWin. | not provided on KWin (decided) |
| HyprlandBackend.qml:156-172, Services/System/Hdr.qml:27-51 | HDR on and off through `monitor cm`, state read from `colorManagementPreset` | `kscreen-doctor output.<name>.hdr.enable` and `.hdr.disable`; `kscreen-doctor -j` reports `"hdr": false` | other API (V for read, A for toggle: this screen does not do HDR) |
| Modules/IPC/IPCManager.qml (IpcHandler) and the `qs ipc call` keybinds | Keybinds call into the shell | `qs ipc` uses Quickshell's own socket, so it does not depend on the compositor. The binds themselves become KDE custom shortcuts (kglobalaccel). | works (A) |
| Services/UI/Actions.qml:21 | `hyprpicker -a` | Needs wlr-screencopy. KWin has `org.kde.kwin.ColorPicker.pick()` on D-Bus. | other API (A: probably restricted like ScreenShot2) |
| Services/Media/Recording.qml:41 | `gpu-screen-recorder -w <region>` | Not installed on the laptop. On KWin, gsr records through the portal or kms. | assumed works through kms (A) |
| SelectionWindow.qml:320,563 | wl-copy | `ext_data_control_manager_v1` is advertised | works (V by protocol) |
| HyprlandBackend.qml:233, PowerActions.qml:23 | Log out | `org.kde.Shutdown.logout()` | other API (V method exists) |
| .claude/skills/qs-test/scripts/qstest.py | `hyprctl`, `grim`, `wtype`, ydotool | wtype failed with "Compositor does not support the virtual keyboard protocol", and grim needs wlr-screencopy. ydotool goes through uinput, so it should work. Screenshots can use spectacle. | the test skill needs a KWin path (V) |

### Desktops per screen

All of this was checked on the laptop, which has one screen.

**The setting:**
- It is stored in `kwinrc`, group `[Windows]`, key `PerOutputVirtualDesktops`. It is a Bool and defaults to false; see `/usr/share/config.kcfg/kwin.kcfg`.
- Read it with `kreadconfig6 --file kwinrc --group Windows --key PerOutputVirtualDesktops --default false`. Here it says `false`.
- A KWin script can read it as `options.perOutputVirtualDesktops`. Here it is `false`.
- `options.separateScreenFocus` is `true` here.

**The KWin script API:**
- Read one screen's desktop: `workspace.currentDesktopForScreen(output)`, which returns a VirtualDesktop.
- Set one screen's desktop: `workspace.setCurrentDesktopForScreen(desktop, output)`. The desktop comes first; the other order fails with "incompatible arguments". Switching to desktop 2 and back on eDP-1 worked.
- Change signal: `workspace.currentDesktopChanged(previous, current, output)`. It fired as `(Desktop 1, Desktop 2, eDP-1)` and then `(Desktop 2, Desktop 1, eDP-1)`, so the KWin backend can track each screen.
- `workspace.currentDesktop` is the desktop of the active screen.

**D-Bus has no per-screen API.** `org.kde.KWin.VirtualDesktopManager` only has the global `current`, and introspecting it shows no output or screen members. The backend must use the script API for this.

**Not verified:** that two screens really switch independently with the option on. That needs a second monitor. I did not turn the option on, because with one screen it would show nothing.

**How this maps to bidshell:**
- KWin has one shared list of desktops, and any desktop can be current on any screen.
- `monitors.<model>.workspaces: [a, b]` becomes "this bar shows desktops a..b, by `x11DesktopNumber`". Clicking one calls `setCurrentDesktopForScreen(desktop, thatScreen)`.
- KWin does not stop another screen from showing the same desktop, but these ranges never overlap, so in practice it behaves like Hyprland's fixed workspace ranges.
- The KWin backend needs at least as many desktops as the highest number in the config. Should the backend create them, or should the user? See question 2.
- With the option off, every screen switches together. The bars still show their own ranges, but a click changes every screen.

### How the KWin backend would get its data

The plan is the same shape as `niri msg event-stream`. Reading back over D-Bus is verified; the full design is not built yet.

1. Load a KWin script through `org.kde.kwin.Scripting.loadScript`.
2. The script pushes JSON events with `callDBus` to a small helper, written with python-gobject (already a dependency).
3. The helper owns a D-Bus name and prints one JSON line per event. A Quickshell `Process` with a `SplitParser` reads the lines.
4. Actions go the other way: either through KWin D-Bus methods, or as one-shot scripts.

Quickshell has no generic D-Bus API in QML, so the helper process is needed.

## 2. Refactor steps (done)

The interface is the desktop session's spec v1: records (Window, ActiveWindow, Monitor, Slot, Bind), capability bools, and Compositor.qml as the only thing modules use. Each step is one `refactor(qs): ...` commit on master, tested on Hyprland before the next one.

1. The ActiveWindow record. The ToplevelManager code is shared in Services/Wayland/ActiveToplevel.qml. Commit: 31d473e.
2. The Window record, `windowsOn`, `workspaceApps` in the facade, and the `covers`, `focused` and `hidden` fields. autoClearOnFocus rules match `appId`. Commit: 6fa3e86.
3. The Monitor record through `monitorFor`: `key`, logical rect, `specialWorkspaceId` and `hdr`. `Compositor.monitors` is removed. Commit: 2107bde.
4. `workspaceSlots(screen)` and `switchWorkspace(id, screen)`. Commit: bd10fa0.
5. HDR: `hasHdrControl` and `setHdr`. Commit: 9dda813.
6. `hasFocusGrab`. Commit: ae0a858.
7. The WindowPreview and ScreenSnapshot components, so ScreencopyView leaves the modules. Commit: ea69c9c.
8. The backend table. `type`, `isHyprland`, `isNiri` and the unused `workspaceFocusChanged` signal are removed. Commit: f9c1e70.

HyprWhichKey stays Hyprland-only. The colour picker (`hyprpicker` in Services/UI/Actions.qml) is decided in the KWin phase.

### The facade contract

This is what a KWin backend must implement. Compositor.qml forwards each member, and its comments give the record shapes. `backends` in Compositor.qml is the table of `[env var, backend path]` pairs; the first one whose variable is set is loaded.

Properties:
- `activeWindow`: `{ appId, title }` of the focused window, with the title live; null when no window has focus.
- `focusedMonitorName`: the output name of the monitor that has focus.
- `windows`: every window as `{ id, appId, title, tag, workspaceId, monitorName, x, y, width, height, floating, covers, focused, hidden }`. Positions are global logical px.
- `describedBinds`: `[{ description, keys }]` for the main keymap; read through `keysFor(description)`.
- `hasWindowGeometry`: whether `x`/`y` are real positions, so the workspace map and window regions can be drawn.
- `hasFocusGrab`: whether a FocusGrab tells popups about outside clicks. When false, popouts cover the screen and take Exclusive keyboard focus.
- `hasHdrControl`: whether `setHdr` works.
- `windowPreviewSource`: the URL of a QML item with `windowId` and `hasContent` that draws one window frame; "" when there are no previews.
- `screenSnapshotSource`: the URL of a QML item with `screen` and `hasContent` that draws one still frame of a screen and nothing else; "" when there are none.

Signals:
- `windowDataUpdated`: windows changed (Notifications auto-clear).
- `monitorDataUpdated`: monitors changed (Hdr).

Functions:
- `monitorFor(screen)`: `{ name, key, x, y, width, height, scale, transform, reserved, activeWorkspaceId, specialWorkspaceId, hdr }` or null. `key` is the config key (the bare model). The rect is logical with the transform applied.
- `workspaceSlots(screen, range)`: the bar's buttons `[{ id, label }]`. `range` is the configured `monitors.<key>.workspaces`, or undefined.
- `activeWorkspaceIdForScreen(screen)`: the workspace that screen shows.
- `switchWorkspace(id, screen)`: switch; `screen` says which output, for per-output desktops.
- `focusWindow(id)`: focus a window from `windows`.
- `refreshWindows()`: re-read the windows now, where the compositor sends no event for moves and resizes.
- `getCursorPosition(callback)`: calls `callback(x, y)` with global logical coordinates.
- `setHdr(monitorName, on)`: switch HDR on that monitor.
- `logout()`: end the session.

The facade itself also provides `windowsOn(workspaceId)`, `workspaceApps(workspaceId)` and `keysFor(description)`.

## 3. Features that cannot work on KWin

| Feature | Why | Hole in |
|---|---|---|
| Live window previews in the workspace map | KWin has no ext-image-copy-capture, wlr-screencopy or toplevel-export. Its own screencast protocol is restricted and Quickshell does not implement it. Still images through ScreenShot2 would need the calling binary to be authorized; decided against. | Both. KWin lacks the standard protocol; Quickshell lacks the KDE one. |
| HyprWhichKey | Not provided on KWin: it stays Hyprland-only | (decided) |
| Live screencopy for the region selector | Same as previews. A still image from spectacle works. | Both |
| hyprpicker | No wlr-screencopy | KWin. KWin's own ColorPicker D-Bus may stand in. |
| Focus-grab protocol | Not in KWin. The Niri fallback covers it. | KWin, but nothing is lost |
| qs-test typing through wtype | No virtual-keyboard protocol | KWin. ydotool still works. |

## 4. Open questions

Decided:
- **Monitor keys.** The KWin backend gives the bare model from the KWin script (refactor step 4).
- **Helper process.** A python-gobject helper is fine. It belongs to the KWin backend, in `feat(kwin)` commits.
- **Plasma's own shell.** bidshell replaces plasmashell. Tests stop plasmashell only for the test, and the desktop session is asked before the first time.
- **HyprWhichKey.** It stays Hyprland-only.
- **qs-test on KWin.** It gets a KWin path later, in the KWin phase.

- **Screenshots.** No ScreenShot2, no `.desktop` authorization, no compiled helper. On KWin, window previews are off (the map shows icons). The region selector uses a `spectacle -b` still.
- **Desktops.** The bar shows desktops a..b from `monitors.<key>.workspaces`, by `x11DesktopNumber`. A click calls `setCurrentDesktopForScreen`. With `PerOutputVirtualDesktops` off, every bar shows all desktops.
- **KWin config is read-only.** The shell never sets `PerOutputVirtualDesktops`, and never creates or deletes desktops. If the config names a desktop that does not exist, the bar skips it and logs one warning.

Nothing is open.
