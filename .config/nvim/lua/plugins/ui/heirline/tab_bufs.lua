local M = {}

local api = vim.api
local get_opt = api.nvim_get_option_value
local cur_buf = api.nvim_get_current_buf
local autocmd = api.nvim_create_autocmd

vim.t.bufs = vim.t.bufs or api.nvim_list_bufs()

local listed_bufs = {}
for _, bufnr in ipairs(vim.t.bufs) do
    if vim.bo[bufnr].buflisted then
        table.insert(listed_bufs, bufnr)
    end
end
vim.t.bufs = listed_bufs

autocmd({ "BufAdd", "BufEnter", "tabnew" }, {
    callback = function(args)
        local bufs = vim.t.bufs
        local is_curbuf = (cur_buf() == args.buf)

        if bufs == nil then
            bufs = is_curbuf and {} or { args.buf }
        else
            if not vim.tbl_contains(bufs, args.buf)
                and (args.event == "BufEnter" or not is_curbuf or get_opt("buflisted", { buf = args.buf }))
                and api.nvim_buf_is_valid(args.buf)
                and get_opt("buflisted", { buf = args.buf })
            then
                table.insert(bufs, args.buf)
            end
        end

        if args.event == "BufAdd" then
            local first_buf = bufs[1]
            if first_buf and #api.nvim_buf_get_name(first_buf) == 0
                and not get_opt("modified", { buf = first_buf })
            then
                table.remove(bufs, 1)
            end
        end

        vim.t.bufs = bufs
    end,
})

-- When a buffer is deleted, remove it from the tab-locals of *all* tabs
autocmd("BufDelete", {
    callback = function(args)
        for _, tabpage in ipairs(api.nvim_list_tabpages()) do
            local bufs = vim.t[tabpage].bufs
            if bufs then
                for i, bufnr in ipairs(bufs) do
                    if bufnr == args.buf then
                        table.remove(bufs, i)
                        vim.t[tabpage].bufs = bufs
                        break
                    end
                end
            end
        end
    end,
})

function M.get_current_tab_bufs()
    return vim.t.bufs or {}
end

return M
