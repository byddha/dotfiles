# hypr_event_emitter.py
import asyncio
import os
from pathlib import Path
from typing import Callable, Any

# A handler can take any args and returns None
Handler = Callable[..., Any]
KeyFilter = Callable[[str, int], bool]


class EventBus:
    def __init__(self) -> None:
        # event name -> list of handlers
        self._handlers: dict[str, list[Handler]] = {}
        # hold_id -> dict[start_fn, end_fn, threshold, key_filter]
        self._hold_defs: dict[str, dict[str, Any]] = {}
        # hold_id -> runtime state dict[handle, fired, keyboard, keycode, threshold, start_cb]
        self._hold_state: dict[str, dict[str, Any]] = {}

    def on(
        self,
        event: str,
        *,
        hold_threshold: float | None = None,
        hold_id: str | None = None,
        key_filter: KeyFilter | None = None,
    ) -> Callable[[Handler], Handler]:
        """
        Register a handler for `event`. If event is 'keyhold_start' or 'keyhold_end',
        you must pass both `hold_threshold` and `hold_id`.
        """

        def decorator(fn: Handler) -> Handler:
            if event in ("keyhold_start", "keyhold_end"):
                if hold_threshold is None or hold_id is None:
                    raise ValueError(
                        "keyhold_start/end require both threshold and hold_id"
                    )
                d = self._hold_defs.setdefault(hold_id, {})
                if event == "keyhold_start":
                    d["start_fn"] = fn
                    d["threshold"] = hold_threshold
                    d["key_filter"] = key_filter
                else:
                    d["end_fn"] = fn
            else:
                self._handlers.setdefault(event, []).append(fn)
            return fn

        return decorator

    async def serve(self) -> None:
        runtime = os.environ["XDG_RUNTIME_DIR"]
        sig = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
        sock = Path(runtime) / "hypr" / sig / ".socket2.sock"
        reader, _ = await asyncio.open_unix_connection(str(sock))

        try:
            while not reader.at_eof():
                line = await reader.readline()
                raw = line.decode(errors="ignore").strip()
                if not raw or ">>" not in raw:
                    continue
                event, payload = raw.split(">>", 1)
                await self._dispatch(event, payload)
        except asyncio.CancelledError:
            return

    async def _dispatch(self, event: str, payload: str) -> None:
        parts = payload.split(",")
        # fire generic handlers
        for fn in self._handlers.get(event, []):
            try:
                fn(*parts)  # type: ignore
            except TypeError:
                fn(payload)  # type: ignore

        if event != "keypress":
            return

        kb, mods, state, code_s = parts
        try:
            code = int(code_s)
        except ValueError:
            return

        loop = asyncio.get_running_loop()

        if state == "down":
            # keydown
            for fn in self._handlers.get("keydown", []):
                fn(keyboard=kb, keycode=code, mods=mods)  # type: ignore

            # schedule hold starts
            for hid, d in self._hold_defs.items():
                filt = d.get("key_filter")
                if filt and not filt(kb, code):
                    continue

                # cancel any existing
                prev = self._hold_state.pop(hid, None)
                if prev:
                    prev["handle"].cancel()

                def make_cb(hid: str):
                    def _cb():
                        st = self._hold_state.get(hid)
                        if st and not st["fired"]:
                            st["fired"] = True
                            d["start_fn"](
                                keyboard=st["keyboard"], keycode=st["keycode"]
                            )  # type: ignore

                    return _cb

                cb = make_cb(hid)
                handle = loop.call_later(d["threshold"], cb)  # threshold is float
                self._hold_state[hid] = {
                    "handle": handle,
                    "fired": False,
                    "keyboard": kb,
                    "keycode": code,
                    "threshold": d["threshold"],
                    "start_cb": cb,
                }

        else:  # state == "up"
            # keyup
            for fn in self._handlers.get("keyup", []):
                fn(keyboard=kb, keycode=code, mods=mods)  # type: ignore

            # complete hold
            for hid, st in list(self._hold_state.items()):
                if st["keyboard"] == kb and st["keycode"] == code:
                    st["handle"].cancel()
                    fired = st["fired"]
                    del self._hold_state[hid]
                    if fired:
                        self._hold_defs[hid]["end_fn"](keyboard=kb, keycode=code)  # type: ignore

    def extend_hold(self, hold_id: str) -> None:
        """
        If a hold is pending (but not yet started/fired), reset its timer.
        """
        st = self._hold_state.get(hold_id)
        if not st or st["fired"]:
            return
        st["handle"].cancel()
        loop = asyncio.get_running_loop()
        st["handle"] = loop.call_later(st["threshold"], st["start_cb"])
