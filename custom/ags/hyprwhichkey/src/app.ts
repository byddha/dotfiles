import { App } from "astal/gtk3";
import style from "./style.scss";
import WhichKey from "./WhichKey";
import { Variable } from "astal";
import AstalHyprland from "gi://AstalHyprland";

const hyprland = AstalHyprland.get_default();
let toggleBaseLayer = () => { };

const binds_arr = Variable<AstalHyprland.Bind[][]>([]);

App.start({
    instanceName: "hyprwhichkey",
    css: style,
    main() {
        let wk = WhichKey({ binds: binds_arr() });

        hyprland.connect("submap", (_, submap) => {
            if (!submap) return wk.set_visible(false);

            setBinds(submap, 4);
            wk.set_visible(true);
        });

        toggleBaseLayer = () => {
            if (wk.visible) return wk.set_visible(false);
            setBinds("", 3);
            wk.set_visible(true);
        };
    },
    requestHandler(_request, res) {
        toggleBaseLayer();
        res("ok");
    },
});

const extra = [
    {
        key: "[q-r]",
        modmask: 64,
        submap: "",
        has_description: true,
        description: " Switch workspace [1-5]",
    },
    {
        key: "[q-r]",
        modmask: 65,
        submap: "",
        has_description: true,
        description: "󰆾 Move workspace [1-5]",
    },
    {
        key: "[a-g]",
        modmask: 64,
        submap: "",
        has_description: true,
        description: " Switch workspace [6-10]",
    },
    {
        key: "[a-g]",
        modmask: 65,
        submap: "",
        has_description: true,
        description: "󰆾 Move workspace [6-10]",
    },
] as AstalHyprland.Bind[];

function setBinds(submap: string, columns: number) {
    let binds = hyprland.get_binds();
    binds.unshift(...extra);
    binds = binds
        .filter(bind => bind.submap === submap && bind.has_description)
        .sort(bind => +(bind.dispatcher === "submap") - 0.5); // make non-submap dispatcher appear first
    const rows = Math.max(Math.ceil(binds.length / columns), 4);

    let r: AstalHyprland.Bind[][] = [];
    for (let i = 0; i < columns; i++) r.push(binds.splice(0, rows));
    binds_arr.set(r);
}
