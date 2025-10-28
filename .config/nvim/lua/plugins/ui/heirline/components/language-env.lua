local python = require "plugins.ui.heirline.components.pythonvenv"
local csharp = require "plugins.ui.heirline.components.csharp-solution"

return {
    fallthrough = false,
    python,
    csharp,
}
