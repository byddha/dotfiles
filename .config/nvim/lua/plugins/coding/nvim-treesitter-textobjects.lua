return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    lazy = false,
    init = function()
        vim.g.no_plugin_maps = true
    end,
    config = function()
        require("nvim-treesitter-textobjects").setup {
            select = {
                lookahead = true,
            },
            move = {
                set_jumps = true,
            },
        }

        local select = require "nvim-treesitter-textobjects.select"
        local move = require "nvim-treesitter-textobjects.move"
        local ts_repeat_move = require "nvim-treesitter-textobjects.repeatable_move"

        local function sel(lhs, query, desc)
            vim.keymap.set({ "x", "o" }, lhs, function()
                select.select_textobject(query, "textobjects")
            end, { desc = desc })
        end

        sel("a=", "@assignment.outer", "Select outer part of an assignment")
        sel("i=", "@assignment.inner", "Select inner part of an assignment")
        sel("l=", "@assignment.lhs", "Select left hand side of an assignment")
        sel("r=", "@assignment.rhs", "Select right hand side of an assignment")
        sel("ap", "@parameter.outer", "Select outer part of a parameter/argument")
        sel("ip", "@parameter.inner", "Select inner part of a parameter/argument")
        sel("ai", "@conditional.outer", "Select outer part of a conditional")
        sel("ii", "@conditional.inner", "Select inner part of a conditional")
        sel("al", "@loop.outer", "Select outer part of a loop")
        sel("il", "@loop.inner", "Select inner part of a loop")
        sel("am", "@call.outer", "Select outer part of a function call")
        sel("im", "@call.inner", "Select inner part of a function call")
        sel("af", "@function.outer", "Select outer part of a method/function definition")
        sel("if", "@function.inner", "Select inner part of a method/function definition")
        sel("ac", "@class.outer", "Select outer part of a class")
        sel("ic", "@class.inner", "Select inner part of a class")

        local function mv(lhs, fn, query, desc)
            vim.keymap.set({ "n", "x", "o" }, lhs, function()
                fn(query, "textobjects")
            end, { desc = desc })
        end

        mv("]m", move.goto_next_start, "@call.outer", "Next function call start")
        mv("]f", move.goto_next_start, "@function.outer", "Next method/function def start")
        mv("]c", move.goto_next_start, "@class.outer", "Next class start")
        mv("]i", move.goto_next_start, "@conditional.outer", "Next conditional start")
        mv("]l", move.goto_next_start, "@loop.outer", "Next loop start")
        mv("]p", move.goto_next_start, "@parameter.inner", "Next parameter/argument")

        mv("]M", move.goto_next_end, "@call.outer", "Next function call end")
        mv("]F", move.goto_next_end, "@function.outer", "Next method/function def end")
        mv("]C", move.goto_next_end, "@class.outer", "Next class end")
        mv("]I", move.goto_next_end, "@conditional.outer", "Next conditional end")
        mv("]L", move.goto_next_end, "@loop.outer", "Next loop end")
        mv("]P", move.goto_next_end, "@parameter.inner", "Next parameter/argument")

        mv("[m", move.goto_previous_start, "@call.outer", "Prev function call start")
        mv("[f", move.goto_previous_start, "@function.outer", "Prev method/function def start")
        mv("[c", move.goto_previous_start, "@class.outer", "Prev class start")
        mv("[i", move.goto_previous_start, "@conditional.outer", "Prev conditional start")
        mv("[l", move.goto_previous_start, "@loop.outer", "Prev loop start")
        mv("[p", move.goto_previous_start, "@parameter.inner", "Prev parameter/argument")

        mv("[M", move.goto_previous_end, "@call.outer", "Prev function call end")
        mv("[F", move.goto_previous_end, "@function.outer", "Prev method/function def end")
        mv("[C", move.goto_previous_end, "@class.outer", "Prev class end")
        mv("[I", move.goto_previous_end, "@conditional.outer", "Prev conditional end")
        mv("[L", move.goto_previous_end, "@loop.outer", "Prev loop end")
        mv("[P", move.goto_previous_end, "@parameter.inner", "Prev parameter/argument")

        vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
        vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

        vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
        vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
        vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
        vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
    end,
}
