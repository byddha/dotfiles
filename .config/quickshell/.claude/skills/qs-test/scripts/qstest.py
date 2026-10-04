#!/usr/bin/env python3
"""Drive the live quickshell like a user, for tests.

  qstest.py start                       play the "testing" sound, restart qs with the debug port, arm the guard
  qstest.py click NAME [N] [--right] [--force]  glide to the Nth match and click (system toggles need --force)
  qstest.py hover NAME [N]              glide there, no click
  qstest.py move X Y [--click]          glide to global logical X Y
  qstest.py wheel N                     scroll N steps at the pointer (N > 0 up, N < 0 down)
  qstest.py drag X1 Y1 X2 Y2            press at X1 Y1, glide to X2 Y2 holding the left button, release
  qstest.py find NAME                   print the matches (x y w h)
  qstest.py eval [#id|type:T] EXPR      run JS in the shell (scope: ShellRoot, or that object; @SCREEN picks one)
  qstest.py wait [#id] EXPR [--timeout=S]   poll until EXPR is truthy (default 3 s), else FAIL
  qstest.py expect [#id] EXPR           check once that EXPR is truthy, else FAIL with its value
  qstest.py see NAME / gone NAME [--timeout=S]  wait until an item is on screen / not on screen
  qstest.py key KEY                     one key into the focused shell surface (wtype), e.g. Escape
  qstest.py type TEXT                   type text (wtype)
  qstest.py bind super+space            compositor keybind (ydotool, real keyboard events)
  qstest.py shot NAME [N] [PAD]         crop screenshot of an item; prints the file path
  qstest.py shot-screen OUTPUT          whole output (a name from `hyprctl monitors`)
  qstest.py shot-rect X Y W H           area in global logical coordinates (popups, tooltips)
  qstest.py test NAME                   start a test: marks the log (each step then prints its new warnings/errors)
  qstest.py done [N]                    end the test: print the log lines it made (last N, default 60)
  qstest.py log                         warnings/errors added since the last `log` (or since `start`)
  qstest.py reload [FILE]               wait for qs to reload after an edit (touch FILE if it does not)
  qstest.py end                         disarm the guard, restart qs without the debug port
  qstest.py batch [FILE|-] [--keep-going] [--sheet [--open]]  run one step per line (stdin without FILE; `#` =
                                        comment) in one process; stops at the first FAIL unless --keep-going; --sheet
                                        puts every shot of the batch into one labelled image, --open also shows it

NAME: `#qmlId`, `type:TypeName`, or text (exact; "~part" = contains); `@SCREEN` limits it to one monitor. Needs qs with a QML debug port: `start`
restarts qs with `--debug` and `end` restarts it without (the port listens on every interface). The guard stops a move when the cursor is not
where the last move left it: the user took the mouse.
"""
import hashlib
import json
import re
import shlex
import shutil
import math
import os
import subprocess
import sys
import time

# Clicks that change the user's machine, not only the UI: refused without --force. A text selector can hit
# them by accident (the "Bluetooth" tile shares its name with the Bluetooth tab and turned Bluetooth off once).
RISKY_TYPES = {"ToggleTile", "Tile", "PowerActionButton"}
RISKY_TEXT = {"Connect", "Disconnect", "Clear All"}

RUNTIME = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "qstest")
STATE = os.path.join(RUNTIME, "state.json")
SHOTS = os.path.join(RUNTIME, "shots")
# Without `end` (crash, interrupted session) the debug port would stay open: restart qs normally after this
WATCHDOG_SECONDS = 1800
SOUND = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "testing.mp3")

GAIN, MAX_STEP, MIN_STEP, STEP_DELAY = 0.18, 50, 2, 0.016
# Linux input event codes (linux/input-event-codes.h) for `bind`
KEYCODES = {"super": 125, "ctrl": 29, "alt": 56, "shift": 42, "space": 57, "escape": 1, "enter": 28, "tab": 15,
            "backspace": 14, "up": 103, "down": 108, "left": 105, "right": 106,
            **dict(zip("qwertyuiop", range(16, 26))), **dict(zip("asdfghjkl", range(30, 39))),
            **dict(zip("zxcvbnm", range(44, 51))), **dict(zip("1234567890", range(2, 12)))}


def run(*cmd, capture=True):
    return subprocess.run(cmd, capture_output=capture, text=True).stdout


def load():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save(state):
    os.makedirs(RUNTIME, exist_ok=True)
    with open(STATE, "w") as f:
        json.dump(state, f)


def cursor():
    x, y = run("hyprctl", "cursorpos").strip().split(",")
    return int(float(x)), int(float(y))


def die(msg):
    print(msg)
    sys.exit(1)


def guard():
    state = load()
    last = state.get("cursor")
    if not state.get("armed"):
        die("not started: run `qstest.py start` first")
    if last and math.dist(last, cursor()) > 3:
        state["armed"] = False
        save(state)
        die(f"STOPPED: the user moved the mouse (expected {tuple(last)}, found {cursor()})")


def step(d):
    if d == 0:
        return 0
    s = min(abs(d), max(MIN_STEP, min(MAX_STEP, round(abs(d) * GAIN))))
    return s if d > 0 else -s


def glide(tx, ty):
    guard()
    # A surface mapped under a resting cursor (qs just restarted or reloaded) gets no pointer enter until
    # the pointer moves: always move, even when already on the target
    if cursor() == (tx, ty):
        run("ydotool", "mousemove", "-x", "-1", "-y", "0")
        time.sleep(STEP_DELAY)
    for _ in range(400):
        cx, cy = cursor()
        dx, dy = tx - cx, ty - cy
        if dx == 0 and dy == 0:
            break
        run("ydotool", "mousemove", "-x", str(step(dx)), "-y", str(step(dy)))
        time.sleep(STEP_DELAY)
    state = load()
    state["cursor"] = list(cursor())
    save(state)
    if tuple(state["cursor"]) != (tx, ty):
        die(f"MISSED: at {tuple(state['cursor'])}, wanted {(tx, ty)}")


def click(button="0xC0"):
    time.sleep(0.06)
    run("ydotool", "click", button)


PORT = int(os.environ.get("QS_DEBUG_PORT", "47777"))

# Runs inside the shell (QML debugger EVAL_EXPRESSION) with a window as scope: walks its items and returns
# the on-screen ones whose text / label / title / tab name matches. Items scrolled out of a clipping
# ancestor, hidden or zero-sized do not count. Coordinates: global logical, the space of hyprctl cursorpos.
# QML type of an item from its string form: "VolumeMixerGroupEntry_QMLTYPE_12(0x...)" -> VolumeMixerGroupEntry
TYPE_FN = r"""function __typeOf(it) {
  return String(it).split("(")[0].replace(/(_QML(TYPE)?_[0-9]+)+$/, "");
}"""

# Walks the window's visual tree (Repeater / Loader items included, unlike the debugger's QObject tree).
# Matches text / label / title / placeholderText / tab name, or the QML type for "type:Name".
TEXT_WALK = r"""(function (query) {
  const typeWanted = query.startsWith("type:") ? query.slice(5) : null;
  const needle = query.startsWith("~") ? query.slice(1).toLowerCase() : null;
  const match = n => needle !== null ? n.toLowerCase().includes(needle) : n === query;
  const out = [];
  function names(it) {
    const r = [];
    for (const k of ["text", "label", "title", "placeholderText"]) {
      const v = it[k];
      if (typeof v === "string" && v !== "") r.push(v);
    }
    const m = it.modelData;
    if (m && typeof m === "object" && typeof m.name === "string" && typeof m.icon === "string") r.push(m.name);
    return r;
  }
  function walk(it) {
    if (!it || !it.visible) return;
    if (typeWanted !== null ? __typeOf(it) === typeWanted : names(it).some(match)) out.push(it);
    for (const c of it.children) walk(c);
  }
  walk(contentItem);
  return JSON.stringify(out.map(__geo).filter(g => g));
})(%s)"""

GEO_FN = r"""function __geo(it) {
  if (!it.visible || it.width <= 0 || it.height <= 0 || it.opacity <= 0) return null;
  for (let a = it.parent; a; a = a.parent) {
    if (!a.clip) continue;
    const r = it.mapToItem(a, 0, 0);
    if (r.x + it.width <= 0 || r.y + it.height <= 0 || r.x >= a.width || r.y >= a.height) return null;
  }
  const p = it.mapToGlobal(0, 0);
  const l = it.mapToItem(null, 0, 0);
  let top = it;
  while (top.parent) top = top.parent;
  return {x: Math.round(p.x), y: Math.round(p.y), w: Math.round(it.width), h: Math.round(it.height), type: __typeOf(it),
          lx: l.x, ly: l.y, ww: Math.round(top.width), wh: Math.round(top.height)};
}"""


def debugger():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    sys.dont_write_bytecode = True  # no __pycache__ in the skill folder (it is in git)
    from qmldbg import QmlDebug
    try:
        return QmlDebug(PORT)
    except OSError:
        die(f"no QML debugger on port {PORT}: run `qstest.py start` (restarts qs with --debug)")


def objects(dbg):
    shell_id = dbg.find_root("ShellRoot")
    if shell_id is None:
        die("ShellRoot not found through the debugger")
    tree = dbg.tree(shell_id)
    stack, out = [tree], []
    while stack:
        n = stack.pop()
        out.append(n)
        stack.extend(reversed(n["children"]))
    return tree, out


# Same test as __geo, for the scope object of the expression (QML expressions have no `this`)
SCOPE_GEO = r"""(function () {
  if (!visible || width <= 0 || height <= 0 || opacity <= 0) return "null";
  if (!Window.window || !Window.window.visible) return "null";
  for (let a = parent; a; a = a.parent) {
    if (!a.clip) continue;
    const r = mapToItem(a, 0, 0);
    if (r.x + width <= 0 || r.y + height <= 0 || r.x >= a.width || r.y >= a.height) return "null";
  }
  const p = mapToGlobal(0, 0);
  const l = mapToItem(null, 0, 0);
  return JSON.stringify({x: Math.round(p.x), y: Math.round(p.y), w: Math.round(width), h: Math.round(height),
                         lx: l.x, ly: l.y, ww: Math.round(Window.width), wh: Math.round(Window.height)});
})()"""


SCREEN_OF = r"""(function () {
  try { if (typeof screen !== "undefined" && screen && screen.name) return screen.name; } catch (e) {}
  try { return QsWindow.window.screen.name; } catch (e) {}
  return "";
})()"""


def split_screen(sel):
    """`#sidebarWindow@HDMI-A-1` -> ("#sidebarWindow", "HDMI-A-1"): pick the instance on that monitor."""
    if "@" in sel and not sel.startswith("~"):
        base, screen = sel.rsplit("@", 1)
        return base, screen
    return sel, None


def evaluate(pos):
    """[#id[@SCREEN]] EXPR: run JS with ShellRoot (or the object with that QML id) as scope.
    Per-monitor components (Variants) make one object per monitor with the same id: `@SCREEN` picks one;
    without it the visible instance wins."""
    dbg = debugger()
    shell, objs = objects(dbg)
    scope = shell["debugId"]
    if len(pos) > 1:
        sel, screen = split_screen(pos[0])
        if sel.startswith("type:"):
            return eval_on_type(dbg, objs, sel[5:], screen, pos[-1])
        else:
            sel = sel[1:] if sel.startswith("#") else sel
            cands = [o["debugId"] for o in objs if o["id"] == sel]
        if not cands:
            die(f"no {pos[0]}")
        if screen:
            cands = [c for c in cands if dbg.eval(c, SCREEN_OF) == screen] or die(f"no #{sel} on {screen}")
        elif len(cands) > 1:
            cands = [c for c in cands if dbg.eval(c, "visible") is True] or cands
        scope = cands[0]
    return dbg.eval(scope, pos[-1])


FIRST_OF_TYPE = r"""(function (typeName) {
  %s
  %s
  function walk(it) {
    if (!it || !it.visible) return null;
    if (__typeOf(it) === typeName && __geo(it)) return it;
    for (const c of it.children) { const r = walk(c); if (r) return r; }
    return null;
  }
  const it = walk(contentItem);
  if (!it) return "__none__";
  with (it) { return (%s); }
})(%s)"""


def visible_windows(dbg, objs):
    """Every visible shell window, whatever its QML type is called (CalendarPopup, TrayMenu, sidebarWindow...):
    the parent of a ProxyWindowContentItem. A property test cannot tell them apart, as child items see the
    window root's properties too."""
    ids = {o["parentId"] for o in objs if o["type"] == "ProxyWindowContentItem"}
    return [o for o in objs if o["debugId"] in ids and dbg.eval(o["debugId"], "visible") is True]


def eval_on_type(dbg, objs, type_name, screen, expr):
    """EXPR with the first on-screen item of that QML type as scope (walks the visual tree of the windows)."""
    for w in visible_windows(dbg, objs):
        if screen and dbg.eval(w["debugId"], SCREEN_OF) != screen:
            continue
        value = dbg.eval(w["debugId"], FIRST_OF_TYPE % (GEO_FN, TYPE_FN, expr, json.dumps(type_name)))
        if value != "__none__":
            return value
    die(f"no type:{type_name} on screen" + (f" on {screen}" if screen else ""))


def monitors():
    return json.loads(run("hyprctl", "monitors", "-j"))


def screen_at(x, y, mons):
    for m in mons:
        w, h = m["width"] / m["scale"], m["height"] / m["scale"]
        if m["x"] <= x < m["x"] + w and m["y"] <= y < m["y"] + h:
            return m["name"]
    return ""


def evljson_scope(dbg, debug_id):
    raw = dbg.eval(debug_id, SCOPE_GEO)
    try:
        return json.loads(raw)
    except (TypeError, ValueError):
        return None  # not an Item (no geometry)


def evaljson(dbg, debug_id, expr):
    raw = dbg.eval(debug_id, expr)
    try:
        return json.loads(raw)
    except (TypeError, ValueError):
        die(f"eval failed: {raw!r}")


def layer_origin(hit, layers):
    """Qt's mapToGlobal puts a layer surface at its monitor's corner (it cannot know where the compositor
    placed it, e.g. a bar on the bottom or right edge), and with fractional scaling even Qt's idea of that
    corner can be off. Take the real place from the one layer with the window's size, on any monitor;
    keep Qt's answer when that is not a single place."""
    if "ww" not in hit:
        return hit
    places = {(l["x"], l["y"]) for mon in layers.values() for level in mon.get("levels", {}).values() for l in level
              if l["w"] == hit["ww"] and l["h"] == hit["wh"]}
    if len(places) != 1:
        return hit
    x, y = places.pop()
    return dict(hit, x=round(x + hit["lx"]), y=round(y + hit["ly"]))


def find(selector):
    """#qmlId, type:TypeName, or text ("~part" = contains), optional @SCREEN. Only items on screen."""
    selector, screen = split_screen(selector)
    mons = monitors()
    layers = json.loads(run("hyprctl", "layers", "-j"))
    hits = [layer_origin(h, layers) for h in find_all(selector)]
    hits = [dict(h, screen=screen_at(h["x"] + h["w"] / 2, h["y"] + h["h"] / 2, mons)) for h in hits]
    return [h for h in hits if not screen or h["screen"] == screen]


def find_all(selector):
    dbg = debugger()
    _, objs = objects(dbg)
    if selector.startswith("#"):
        # QML ids only exist in the debugger's object tree (items made by a Repeater are not in it:
        # reach those by type or text)
        want = selector[1:]
        hits = []
        for o in objs:
            if o["id"] == want:
                g = evljson_scope(dbg, o["debugId"])
                if g:
                    hits.append(dict(g, type=o["type"]))
        return hits
    hits = []
    for w in visible_windows(dbg, objs):
        expr = "(function(){" + GEO_FN + ";" + TYPE_FN + "; return " + TEXT_WALK % json.dumps(selector) + ";})()"
        raw = dbg.eval(w["debugId"], expr)
        if isinstance(raw, str) and raw.startswith("["):
            hits.extend(json.loads(raw))
    return hits


def target(name, index):
    """The Nth match, once it stopped moving (open / slide animations), so a click never hits a moving item."""
    last = None
    for _ in range(30):
        hits = find(name)
        if len(hits) <= index:
            die(f"NOT FOUND: {name!r} [{index}] ({len(hits)} matches)")
        if hits[index] == last:
            return last
        last = hits[index]
        time.sleep(0.08)
    die(f"NOT STABLE: {name!r} [{index}] still moving")


def center(hit):
    return hit["x"] + hit["w"] // 2, hit["y"] + hit["h"] // 2


ANSI = re.compile(r"\x1b\[[0-9;]*m")
# Config.qml prints the whole config, API keys included: never show it
SECRET = ("Full config",)


def log_lines():
    return [ANSI.sub("", l) for l in run("qs", "log").splitlines()]


def readable(lines):
    return [l for l in lines if l.strip() and not any(s in l for s in SECRET)]


def problems(lines):
    keep = ("WARN", "ERROR", "TypeError", "ReferenceError")
    skip = ("brightnessctl", "scoped_dir") + SECRET
    return [l for l in lines if any(k in l for k in keep) and not any(s in l for s in skip)]


def restart_qs(extra):
    # After a crash Quickshell restarts itself as "quickshell", not "qs"
    subprocess.run(["pkill", "-x", "qs|quickshell"])
    time.sleep(1)
    subprocess.Popen(["qs", "-d", *extra], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(40):
        time.sleep(0.25)
        if not extra or f":{extra[-1]} " in run("ss", "-ltn"):
            break
    time.sleep(1.5)


def reload_count():
    return sum("Configuration Loaded" in l for l in log_lines())


ACTIONS = {"click", "hover", "move", "wheel", "drag", "key", "type", "bind", "eval", "shot", "shot-screen", "shot-rect", "wait", "expect", "see", "gone"}


def report_new_problems():
    """After each step: warnings / errors the step made (keeps the per-step log mark)."""
    state = load()
    if not state.get("armed"):
        return
    lines = log_lines()
    new = problems(lines[state.get("log", 0):])
    state["log"] = len(lines)
    save(state)
    for line in new:
        print("  LOG " + line.strip())


# Shots taken in this process, as (step, path): `batch --sheet` joins them into one image
SHOTS_TAKEN = []


def batch_args(line):
    """Like the shell, except that for eval / wait / expect the rest of the line is the JS expression, unquoted
    (`wait #sidebarWindow visible && presented`); a first word starting with # or type: is the scope."""
    cmd, _, rest = line.partition(" ")
    if cmd not in ("eval", "wait", "expect"):
        return shlex.split(line)
    words = rest.split()
    flags = [w for w in words if w.startswith("--timeout=")]
    words = [w for w in words if not w.startswith("--timeout=")]
    scope = [words.pop(0)] if words and words[0].startswith(("#", "type:")) else []
    return [cmd, *scope, " ".join(words), *flags]


def batch(pos, flags):
    src = sys.stdin if not pos or pos[0] == "-" else open(pos[0])
    lines = [l.strip() for l in src.read().splitlines()]
    failed = 0
    for line in lines:
        if not line or line.startswith("#"):
            continue
        print(f"> {line}", flush=True)
        try:
            run_step(batch_args(line))
        except SystemExit as e:
            if e.code in (0, None):
                continue
            failed += 1
            # Never go on after the guard stopped (the user has the mouse) or outside a session
            if "--keep-going" not in flags or not load().get("armed"):
                break
        finally:
            sys.stdout.flush()
    if "--sheet" in flags and SHOTS_TAKEN:
        sheet = os.path.join(SHOTS, f"sheet-{int(time.time() * 1000)}.png")
        cells = []
        for label, path in SHOTS_TAKEN:
            cells += ["-label", label, path]
        run("magick", "montage", *cells, "-tile", "2x", "-geometry", "+12+12", "-pointsize", "18",
            "-background", "#202020", "-fill", "#e0e0e0", sheet)
        print(f"SHEET {sheet}")
        # Only on request: a viewer popping up on the user's screen can take the focus the next steps need
        if "--open" in flags:
            subprocess.Popen(["xdg-open", sheet], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    if failed:
        sys.exit(1)


def main(args):
    if not args:
        die(__doc__)
    cmd, rest = args[0], args[1:]
    flags = {a for a in rest if a.startswith("--")}
    pos = [a for a in rest if not a.startswith("--")]
    idx = int(pos[1]) if len(pos) > 1 and pos[1].isdigit() else 0

    if cmd == "batch":
        batch(pos, flags)
    elif cmd == "start":
        # Tell the user to let go of the mouse: play the sound to the end (it is the warning time)
        if subprocess.run(["pw-play", SOUND], capture_output=True).returncode != 0:
            run("notify-send", "-t", "2500", "-a", "Claude", "Test starts", "Don't touch the mouse")
            time.sleep(1)
        # ydotoold runs only during a test, so its virtual keyboard asks Hyprland's keyboard
        # permission: the user allows it for this run
        subprocess.run(["systemctl", "--user", "start", "ydotool"], capture_output=True)
        if f":{PORT} " not in run("ss", "-ltn"):
            restart_qs(["--debug", str(PORT)])
        # Startup keeps logging for a moment (async services): wait until the log is quiet for 1 s
        count, quiet_since, give_up = -1, time.monotonic(), time.monotonic() + 8
        while time.monotonic() - quiet_since < 1.0 and time.monotonic() < give_up:
            now = len(log_lines())
            if now != count:
                count, quiet_since = now, time.monotonic()
            time.sleep(0.2)
        shutil.rmtree(SHOTS, ignore_errors=True)
        session = str(time.time())
        save({"armed": True, "session": session, "cursor": list(cursor()), "log": len(log_lines()),
              "reloads": reload_count()})
        subprocess.Popen([sys.executable, os.path.abspath(__file__), "watchdog", session],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        print("armed")
    elif cmd == "end":
        state = load()
        state["armed"] = False
        state["session"] = None
        save(state)
        # The debug port listens on every interface: never leave it open after a test
        if "--keep" not in flags:
            subprocess.run(["systemctl", "--user", "stop", "ydotool"], capture_output=True)
            if f":{PORT} " in run("ss", "-ltn"):
                restart_qs([])
        print("disarmed")
    elif cmd == "watchdog":
        time.sleep(WATCHDOG_SECONDS)
        if load().get("session") == pos[0] and f":{PORT} " in run("ss", "-ltn"):
            state = load()
            state["armed"] = False
            save(state)
            subprocess.run(["systemctl", "--user", "stop", "ydotool"], capture_output=True)
            restart_qs([])
    elif cmd == "eval":
        print(evaluate(pos))
    elif cmd in ("wait", "expect"):
        # JS truthiness of EXPR; `wait` polls until true (--timeout seconds, default 3), `expect` checks once
        timeout = float(next((a.split("=", 1)[1] for a in rest if a.startswith("--timeout=")), 3))
        expr = f"!!({pos[-1]})"
        end = time.monotonic() + (timeout if cmd == "wait" else 0)
        while True:
            value = evaluate(pos[:-1] + [expr])
            if value is True:
                print(f"ok {pos[-1]}")
                break
            if time.monotonic() >= end:
                die(f"FAIL {cmd} {pos[-1]}: {evaluate(pos[:-1] + [pos[-1]])!r}")
            time.sleep(0.1)
    elif cmd in ("see", "gone"):
        # Wait until an item is on screen (see) or no longer on screen (gone)
        timeout = float(next((a.split("=", 1)[1] for a in rest if a.startswith("--timeout=")), 3))
        end = time.monotonic() + timeout
        while True:
            found = bool(find(pos[0]))
            if found == (cmd == "see"):
                print(f"ok {cmd} {pos[0]}")
                break
            if time.monotonic() >= end:
                die(f"FAIL {cmd} {pos[0]}")
            time.sleep(0.1)
    elif cmd in ("click", "hover"):
        hit = target(pos[0], idx)
        if cmd == "click" and "--force" not in flags and (hit.get("type") in RISKY_TYPES or pos[0].split("@")[0] in RISKY_TEXT):
            die(f"REFUSED: {pos[0]!r} is a {hit.get('type')} that changes the system (toggle, power, connect). "
                "Pick a more exact selector (index, #id, @SCREEN) or add --force if the user agreed.")
        x, y = center(hit)
        glide(x, y)
        if cmd == "click":
            click("0xC1" if "--right" in flags else "0xC0")
        print(f"{cmd} {pos[0]} at {x},{y}")
    elif cmd == "drag":
        # Press at X1 Y1, glide to X2 Y2 with the button held, release (left button)
        x1, y1, x2, y2 = (int(v) for v in pos[:4])
        glide(x1, y1)
        time.sleep(0.06)
        run("ydotool", "click", "0x40")
        time.sleep(0.05)
        glide(x2, y2)
        time.sleep(0.06)
        run("ydotool", "click", "0x80")
        print(f"drag {x1},{y1} -> {x2},{y2}")
    elif cmd == "move":
        glide(int(pos[0]), int(pos[1]))
        if "--click" in flags:
            click()
        print(f"at {pos[0]},{pos[1]}")
    elif cmd == "wheel":
        # At the pointer: positive steps scroll up (angleDelta.y > 0), negative ones down
        guard()
        for _ in range(abs(int(pos[0]))):
            run("ydotool", "mousemove", "-w", "-x", "0", "-y", "1" if int(pos[0]) > 0 else "-1")
            time.sleep(0.15)
        print(f"wheel {pos[0]}")
    elif cmd == "find":
        for h in find(pos[0]):
            print(h["x"], h["y"], h["w"], h["h"], h["screen"])
    elif cmd == "key":
        run("wtype", "-k", pos[0])
    elif cmd == "type":
        run("wtype", pos[0])
    elif cmd == "bind":
        codes = [KEYCODES[k] for k in pos[0].lower().split("+")]
        seq = [f"{c}:1" for c in codes] + [f"{c}:0" for c in reversed(codes)]
        run("ydotool", "key", *seq)
    elif cmd == "shot":
        hit = target(pos[0], idx)
        pad = int(pos[2]) if len(pos) > 2 else 8
        os.makedirs(SHOTS, exist_ok=True)
        path = os.path.join(SHOTS, f"{int(time.time() * 1000)}.png")
        geo = f"{hit['x'] - pad},{hit['y'] - pad} {hit['w'] + 2 * pad}x{hit['h'] + 2 * pad}"
        run("grim", "-g", geo, path)
        SHOTS_TAKEN.append((" ".join(args), path))
        print(path)
    elif cmd in ("shot-screen", "shot-rect"):
        os.makedirs(SHOTS, exist_ok=True)
        path = os.path.join(SHOTS, f"{pos[0] if cmd == 'shot-screen' else 'rect'}-{int(time.time() * 1000)}.png")
        where = ["-o", pos[0]] if cmd == "shot-screen" else ["-g", f"{pos[0]},{pos[1]} {pos[2]}x{pos[3]}"]
        # Retake until two shots in a row are equal, so a running animation is never captured half-way
        last = None
        for _ in range(12):
            run("grim", *where, path)
            with open(path, "rb") as f:
                digest = hashlib.md5(f.read()).hexdigest()
            if digest == last:
                break
            last = digest
            time.sleep(0.15)
        SHOTS_TAKEN.append((" ".join(args), path))
        print(path)
    elif cmd == "test":
        state = load()
        n = len(log_lines())
        state.update({"test": " ".join(pos), "test_log": n, "log": n})
        save(state)
        print(f"== {state['test']}")
    elif cmd == "done":
        state = load()
        lines = readable(log_lines()[state.get("test_log", 0):])
        print(f"== {state.get('test', '?')}: {len(lines)} log lines")
        for line in lines[-int(pos[0]) if pos else -60:]:
            print("  " + line.strip())
        state["log"] = len(log_lines())
        save(state)
    elif cmd == "log":
        state = load()
        lines = log_lines()
        new = problems(lines[state.get("log", 0):])
        state["log"] = len(lines)
        save(state)
        print("\n".join(new) if new else "log clean")
    elif cmd == "reload":
        state = load()
        before = state.get("reloads", reload_count())
        for attempt in range(2):
            for _ in range(20):
                count = reload_count()
                if count > before:
                    state["reloads"] = count
                    save(state)
                    print("reloaded")
                    return
                time.sleep(0.25)
            if pos:
                os.utime(pos[0])
        die("NO RELOAD")
    else:
        die(__doc__)


def run_step(args):
    try:
        main(args)
    finally:
        # Also after a FAIL: the log of a failing step matters most
        if args and args[0] in ACTIONS:
            report_new_problems()


run_step(sys.argv[1:])
