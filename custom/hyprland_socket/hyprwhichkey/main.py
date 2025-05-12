import asyncio
import subprocess


from hyprsnake.event_bus import EventBus


async def main():
    em = EventBus()
    latest_submap = ""
    WIN_KEY = 133

    @em.on("keydown")
    def keydown(keyboard: str, mods: int, keycode: int):
        if keycode != 133:
            em.extend_hold("panel")

    @em.on("submap")
    def submap(name: str):
        nonlocal latest_submap
        latest_submap = name

    @em.on(
        "keyhold_start",
        hold_threshold=0.5,
        hold_id="panel",
        key_filter=lambda kb, code: code == WIN_KEY,
    )
    def keys_show(keyboard: str, keycode: int):
        nonlocal latest_submap
        if latest_submap == "":
            _ = subprocess.run(
                ["astal", "-i", "hyprwhichkey"],
                capture_output=False,
            )

    @em.on(
        "keyhold_end",
        hold_threshold=0.5,
        hold_id="panel",
        key_filter=lambda kb, code: code == WIN_KEY,
    )
    def keys_hide(keyboard: str, keycode: int):
        nonlocal latest_submap
        if latest_submap == "":
            _ = subprocess.run(
                ["astal", "-i", "hyprwhichkey"],
                capture_output=False,
            )

    await em.serve()


if __name__ == "__main__":
    asyncio.run(main())
