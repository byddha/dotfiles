// Started from : https://github.com/Juhan280/hyprwhichkey?tab=readme-ov-file#showcase
import { App, Astal, Widget } from "astal/gtk3";
import { Binding } from "astal";
import Grid from "./Grid";
import AstalHyprland from "gi://AstalHyprland";

// See https://github.com/hyprwm/Hyprland/blob/1989b0049f7fb714a2417dfb14d6b4f3d2a079d3/src/devices/IKeyboard.hpp#L12-L21
const modkeys = ["shift", "caps", "ctrl", "alt", "mod2", "mod3", "super", "mod5"] as const;

function modmaskToKeys(modmask: number): string {
    return modkeys
        .filter((_, i) => (modmask >> i) & 1)
        .map(key => `<${key}>`)
        .reverse()
        .join(" ");
}

const MOD_ICON: Record<string, string> = {
    "<shift>": "⇪",
    "<ctrl>": "󰘴",
    "<alt>": "",
    "<super>": "󰣇",
    "<caps>": "󰪛",
    "<mod2>": "Num",
    "<mod3>": "ScrLk",
    "<mod5>": "Compose",
};


// count actual characters (not code units)
function visualLength(s: string): number {
    return Array.from(s).length
}

// left-pad to `width` *visual* columns
function padVisual(s: string, width: number, fill = " "): string {
    const len = visualLength(s)
    if (len >= width) return s
    return fill.repeat(width - len) + s
}

function key(entry: AstalHyprland.Bind, padding = 0) {
    let mod = modmaskToKeys(entry.modmask)
    for (const [ph, gl] of Object.entries(MOD_ICON)) {
        if (!gl) continue
        mod = mod.replaceAll(ph, gl)
    }
    const full = `${mod} ${entry.key}`
    // pad by *visual* width, not code-unit length:
    return padVisual(full, padding)
}




function Keybind({ entry, padding }: { entry: AstalHyprland.Bind; padding: number }) {
    const rawDesc =
        entry.description ||
        entry.dispatcher + (entry.arg ? `: ${entry.arg}` : "");

    const chars = Array.from(rawDesc);
    let descGlyph = "";
    let descText = rawDesc;

    if (chars.length > 0 && /^[^\p{L}\p{N}]/u.test(chars[0])) {
        descGlyph = " " + chars[0];                // full glyph, not half a surrogate
        descText = chars.slice(1).join(""); // the rest joined back into a string
    } else {
        descText = " " + descText;
    }

    return (
        <box className="keybind" orientation="horizontal" spacing={4}>
            <label className="key">{key(entry, padding)}</label>
            <label className="arrow"></label>

            {descGlyph && <label className="desc-glyph">{descGlyph}</label>}
            <label className={entry.dispatcher === "submap" ? "submap" : descText ? "desc" : ""}>
                {descText}
            </label>
        </box>
    );
}



export default function WhichKey({ binds }: { binds: Binding<AstalHyprland.Bind[][]> }) {
    const { BOTTOM } = Astal.WindowAnchor;

    return (
        <window
            name="WhichKey"
            className="whichkey"
            namespace="hyprwhichkey"
            layer={Astal.Layer.OVERLAY}
            visible={false}
            monitor={0}
            anchor={BOTTOM}
            onNotifyVisible={self => self.visible && self.set_click_through(true)}
            application={App}
        >
            {binds.as(binds => (
                <Grid
                    className="container"
                    column-homogeneous
                    rowSpacing={2}
                    setup={self => {
                        for (let i = 0; i < binds.length; i++) {
                            let padding = 0;
                            for (let j = 0; j < binds[i].length; j++)
                                padding = Math.max(padding, key(binds[i][j]).length);

                            for (let j = 0; j < binds[i].length; j++)
                                self.attach(<Keybind entry={binds[i][j]} padding={padding} />, i, j, 1, 1);
                        }
                    }}
                />
            ))}
        </window>
    ) as Widget.Window;
}
