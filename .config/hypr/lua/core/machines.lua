local M = {}

local configs = {
    bidaPC = {
        profile      = "desktop",
        monitors     = {
            main = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. MO34WQC2",
            mini = "desc:Invalid Vendor Codename - RTK 0x1920",
        },
        touch_output = "desc:Invalid Vendor Codename - RTK 0x1920",
    },
}

local fallback = {
    profile  = "notebook",
    monitors = {
        builtin = "eDP-1",
    },
}

function M.for_hostname(hostname)
    return configs[hostname] or fallback
end

return M
