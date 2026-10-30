-- Core Settings
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true
vim.opt.timeoutlen = 300
vim.opt.laststatus = 0
vim.opt.cmdheight = 1
vim.opt.errorformat = "%f:%l:%c: %t%*[^:]: %m"
vim.opt.number = true
--vim.opt.relativenumber = true

-- Theme & UI (Pablo Customization)
local function swap_pablo_blues()
    local highlights = vim.api.nvim_get_hl(0, {})
    for name, info in pairs(highlights) do
        if info.fg == 255 or info.ctermfg == 4 or info.ctermfg == 12 then
            vim.api.nvim_set_hl(0, name, {
                fg = "#0088ff",
                bold = info.bold,
                italic = info.italic,
                underline = info.underline,
            })
        end
    end
    -- Keep everything pitch black
    vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE", fg = "#555555" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#000000" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#000000", fg = "#555555" })
    vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE", fg = "#000000" })
end

vim.cmd('colorscheme pablo')
swap_pablo_blues()

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "pablo",
    callback = swap_pablo_blues,
})

-- Warning Checker (Native Clang)
local clang_buf = nil
local function run_clang_native()
    local file = vim.fn.expand("%:p")
    if file == "" then return end

    if clang_buf and vim.api.nvim_buf_is_valid(clang_buf) then
        vim.api.nvim_buf_delete(clang_buf, { force = true })
    end

    vim.cmd("silent w")
    
    local qf_file = vim.fn.tempname()
    local cmd = string.format("clang -Wall -Wextra -fcolor-diagnostics -fsyntax-only -std=c23 %s 2>&1 | tee %s", 
                vim.fn.shellescape(file), vim.fn.shellescape(qf_file))
    
    vim.cmd("botright 10new")
    clang_buf = vim.api.nvim_get_current_buf()
    
    vim.fn.termopen(cmd, {
        on_exit = function()
            vim.cmd("cgetfile " .. qf_file)
            os.remove(qf_file)
        end
    })

    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.keymap.set('n', 'q', ':close<CR>', { buffer = clang_buf, silent = true })
    vim.cmd("normal! G")
end

-- Raylib Runner (Saves automatically)
local function comp_prg()
    local file = vim.fn.expand("%:p")
    if file == "" then return end

    -- Save file automatically
    vim.cmd("silent w")

    local raw_cmd = string.format(
        "clang-20 %s -o main.out -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 -std=c23 -fcolor-diagnostics 2>&1 && ./main.out; rm main.out",
        vim.fn.shellescape(file)
    )

    vim.cmd("botright 15new")
    local bufnr = vim.api.nvim_get_current_buf()
    vim.fn.termopen({ "sh", "-c", raw_cmd })

    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    
    -- Safety mappings for this buffer
    vim.keymap.set('n', '<leader>q', ':close<CR>', { buffer = bufnr, silent = true })
    vim.keymap.set('t', '<leader>q', '<Nop>', { buffer = bufnr, silent = true })
    vim.keymap.set('t', 'jj', [[<C-\><C-n>]], { buffer = bufnr, silent = true })
    
    vim.cmd("startinsert")
end

-- Keymaps (General)
vim.keymap.set({'i', 'v', 'x'}, 'jj', '<Esc>')
vim.keymap.set('t', 'jj', [[<C-\><C-n>]])
vim.keymap.set('n', '<leader>s', ':w<CR>')

-- Global Close Override
pcall(vim.keymap.del, 'n', '<leader>q')
vim.keymap.set('n', '<leader>q', ':close<CR>', { silent = true })

-- Workflow Mappings
vim.keymap.set('n', '<leader>d', run_clang_native)
vim.keymap.set('n', '<leader>r', comp_prg)

-- Filetype specific fixes
vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function() vim.cmd("setlocal syntax=qf") end,
})

-- Start the native LSP client for C
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        vim.lsp.start({
            name = "clangd",
            cmd = { "clangd" },
            root_dir = vim.fs.dirname(vim.fs.find({ "main.c", ".git" }, { upward = true })[1]),
        })
    end,
})

vim.keymap.set('i', '<C-Space>', function()
    if next(vim.lsp.get_active_clients({ bufnr = 0 })) then
        return "<C-x><C-o>"
    else
        return "<C-x><C-n>"
    end
end, { expr = true, desc = "Smart Autocomplete" })

vim.api.nvim_create_autocmd("InsertCharPre", {
    callback = function()
        if vim.fn.pumvisible() == 0 and vim.v.char:match("[%w_]") then
            local key = vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true)
            vim.api.nvim_feedkeys(key, "n", false)
        end
    end,
})

-- Don't show the "Pattern not found" or "match 1 of 2" messages
vim.opt.shortmess:append("c")

-- Essential for auto-popup behavior
vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert" }

-- Configure native diagnostics
vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    update_in_insert = false,
})

-- Instant Warning Popup Logic
vim.api.nvim_create_autocmd("CursorMoved", {
    callback = function()
        local line = vim.api.nvim_win_get_cursor(0)[1] - 1
        local diags = vim.diagnostic.get(0, { lnum = line })
        
        local float_open = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_config(win).relative ~= "" then
                float_open = true
                break
            end
        end

        if #diags > 0 and not float_open then
            vim.diagnostic.open_float(nil, {
                focusable = false,
                close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "InsertCharPre" },
                border = "single",
                scope = "line",
                header = "",
                prefix = "",
            })
        end
    end,
})

-- Warning colors (Plain text approach)
vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#FFA500" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = "#FFA500" })

-- Persistent Statusbar Killer
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "FileType" }, {
    callback = function()
        vim.opt.laststatus = 0
    end,
})

-- Final call to ensure UI is set on startup
swap_pablo_blues()
