#!/usr/bin/env python3
"""Runs bidshell's KWin script and relays it for KWinBackend.qml.

Prints one JSON line per message on stdout: {"state": ...} on every change the script sends over D-Bus,
with each output's config key added; {"cursor": [x, y]} after a "cursor" action; {"shortcuts": ...}, the
kglobalaccel keys of KWin's and the session's actions as labels, at start and when they change. Actions
come in as JSON lines on stdin and run as one-shot KWin scripts. Exits when stdin closes or the parent
dies, and unloads its scripts then.
"""
import ctypes
import glob
import json
import os
import signal
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

SERVICE = "org.bidshell.KWin"
SCRIPT = "bidshell"
ACTION = "bidshell-action"
HERE = os.path.dirname(os.path.abspath(__file__))
ACTION_FILE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "bidshell-kwin-action.js")
INTERFACE = Gio.DBusNodeInfo.new_for_xml(f"""
<node><interface name="{SERVICE}">
<method name="State"><arg type="s" direction="in"/></method>
<method name="Cursor"><arg type="s" direction="in"/></method>
</interface></node>
""").interfaces[0]

bus = Gio.bus_get_sync(Gio.BusType.SESSION)
loop = GLib.MainLoop()
pending = None
keys = {}


def kwin(path, interface, method, args=None):
    return bus.call_sync("org.kde.KWin", path, interface, method, args, None, Gio.DBusCallFlags.NONE, -1, None)


def unload(plugin):
    kwin("/Scripting", "org.kde.kwin.Scripting", "unloadScript", GLib.Variant("(s)", (plugin,)))


def run_script(path, plugin):
    unload(plugin)
    script_id = kwin("/Scripting", "org.kde.kwin.Scripting", "loadScript", GLib.Variant("(ss)", (path, plugin))).unpack()[0]
    kwin(f"/Scripting/Script{script_id}", "org.kde.kwin.Script", "run")


def monitor_key(output):
    """The monitor's model as Hyprland reports it: the EDID monitor name, or the product code without one."""
    for path in glob.glob(f"/sys/class/drm/card*-{output}/edid"):
        edid = open(path, "rb").read()
        if len(edid) < 128:
            continue
        for start in range(54, 126, 18):
            block = edid[start:start + 18]
            if block[:3] == b"\0\0\0" and block[3] == 0xFC:
                name = block[5:].split(b"\n")[0].decode("ascii", "replace").strip(" \0")
                if name and name.isprintable():
                    return name
        return f"0x{int.from_bytes(edid[10:12], 'little'):04X}"
    return output


def emit(message):
    print(json.dumps(message), flush=True)


def flush():
    global pending
    state = json.loads(pending)
    pending = None
    for output in state["outputs"]:
        output["key"] = keys.setdefault(output["name"], monitor_key(output["name"]))
    emit({"state": state})
    return False


def on_call(connection, sender, path, interface, method, params, invocation):
    global pending
    if method == "Cursor":
        emit({"cursor": json.loads(params.unpack()[0])})
    else:
        if pending is None:
            GLib.idle_add(flush)
        pending = params.unpack()[0]
    invocation.return_value(None)


SHORTCUT_COMPONENTS = ["kwin", "ksmserver", "org_kde_powerdevil"]
MODIFIERS = [(0x10000000, "Super"), (0x04000000, "Ctrl"), (0x08000000, "Alt"), (0x02000000, "Shift")]
KEY_NAMES = {0x20: "Space", 0x01000000: "Escape", 0x01000001: "Tab", 0x01000003: "Backspace", 0x01000004: "Return",
             0x01000005: "Enter", 0x01000006: "Insert", 0x01000007: "Delete", 0x01000008: "Pause", 0x01000009: "Print",
             0x01000010: "Home", 0x01000011: "End", 0x01000012: "Left", 0x01000013: "Up", 0x01000014: "Right",
             0x01000015: "Down", 0x01000016: "PageUp", 0x01000017: "PageDown"}


def key_label(code):
    """A Qt key code with modifiers as Hyprland's labels read ("Super Shift Q"); "" for keys without a name here."""
    key = code & 0x01FFFFFF
    if 0x21 <= key <= 0x7E:
        name = chr(key).upper()
    elif 0x01000030 <= key <= 0x01000052:
        name = f"F{key - 0x01000030 + 1}"
    else:
        name = KEY_NAMES.get(key, "")
    return " ".join([label for bit, label in MODIFIERS if code & bit] + [name]) if name else ""


def read_shortcuts(*_):
    shortcuts = {}
    for component in SHORTCUT_COMPONENTS:
        try:
            infos = bus.call_sync("org.kde.kglobalaccel", f"/component/{component}", "org.kde.kglobalaccel.Component",
                                  "allShortcutInfos", None, None, Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
        except GLib.Error:
            continue
        for action, _, _, _, _, _, codes, _ in infos:
            labels = [label for label in map(key_label, codes) if label]
            # Of several keys for one action, the one with Super, as a Hyprland bind would be
            label = next((label for label in labels if label.startswith("Super")), labels[0] if labels else "")
            if label:
                shortcuts[f"{component}/{action}"] = label
    emit({"shortcuts": shortcuts})


def act(command):
    if command["action"] == "logout":
        bus.call_sync("org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown", "logout", None, None, Gio.DBusCallFlags.NONE, -1, None)
        return
    if command["action"] == "cursor":
        body = f"callDBus({json.dumps(SERVICE)}, \"/bidshell\", {json.dumps(SERVICE)}, \"Cursor\", JSON.stringify([workspace.cursorPos.x, workspace.cursorPos.y]));"
    elif command["action"] == "switch":
        body = f"""const desktop = workspace.desktops.find(d => d.x11DesktopNumber === {json.dumps(command["desktop"])});
const output = workspace.screens.find(s => s.name === {json.dumps(command["output"])});
if (desktop && output)
    workspace.setCurrentDesktopForScreen(desktop, output);
else if (desktop)
    workspace.currentDesktop = desktop;"""
    elif command["action"] == "focus":
        body = f"""const window = workspace.windowList().find(w => w.internalId.toString() === {json.dumps(command["id"])});
if (window)
    workspace.activeWindow = window;"""
    else:
        print(f"kwin_bridge: unknown action {command['action']}", file=sys.stderr)
        return
    with open(ACTION_FILE, "w") as f:
        f.write(body)
    run_script(ACTION_FILE, ACTION)


def on_stdin(channel, condition):
    line = sys.stdin.readline()
    if not line:
        loop.quit()
        return False
    try:
        act(json.loads(line))
    except (ValueError, KeyError, GLib.Error) as e:
        print(f"kwin_bridge: {line.strip()}: {e}", file=sys.stderr)
    return True


# Only now does the script's first state reach this bridge, not the one it replaces
def on_name_acquired(*_):
    run_script(os.path.join(HERE, "bidshell.js"), SCRIPT)


def on_name_lost(*_):
    loop.quit()


def owns_name():
    try:
        owner = bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "GetNameOwner",
                              GLib.Variant("(s)", (SERVICE,)), None, Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
    except GLib.Error:
        return False
    return owner == bus.get_unique_name()


def main():
    # PR_SET_PDEATHSIG: SIGTERM when quickshell dies, even without closing stdin
    ctypes.CDLL(None).prctl(1, signal.SIGTERM)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, loop.quit)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, loop.quit)

    bus.register_object("/bidshell", INTERFACE, on_call)
    # A new bridge (after a reload) takes the name over, and the old one exits
    Gio.bus_own_name_on_connection(bus, SERVICE, Gio.BusNameOwnerFlags.ALLOW_REPLACEMENT | Gio.BusNameOwnerFlags.REPLACE,
                                   on_name_acquired, on_name_lost)
    for signal_name in ["yourShortcutGotChanged", "yourShortcutsChanged"]:
        bus.signal_subscribe("org.kde.kglobalaccel", "org.kde.KGlobalAccel", signal_name, "/kglobalaccel", None,
                             Gio.DBusSignalFlags.NONE, read_shortcuts)
    read_shortcuts()
    GLib.io_add_watch(GLib.IOChannel.unix_new(sys.stdin.fileno()), GLib.PRIORITY_DEFAULT,
                      GLib.IOCondition.IN | GLib.IOCondition.HUP, on_stdin)
    try:
        loop.run()
    finally:
        # A bridge that took the name over (a reload) runs the scripts now; only the last one unloads them
        if owns_name():
            unload(SCRIPT)
            unload(ACTION)


if __name__ == "__main__":
    main()
