-- Core Settings
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true
vim.opt.timeoutlen = 300
vim.opt.errorformat = "%f:%l:%c: %t%*[^:]: %m"
vim.opt.number = true

-- Tab and Indentation Settings (2 Spaces, 1 Space Backspace)
vim.opt.expandtab = true   -- Convert tabs to spaces
vim.opt.tabstop = 2        -- Insert 2 spaces for a physical tab character
vim.opt.shiftwidth = 2     -- Indent by 2 spaces when using shift commands (e.g., >> or <<)
vim.opt.softtabstop = 0    -- Force backspace to always delete exactly 1 space

-- UI Configuration
vim.opt.laststatus = 0
vim.opt.cmdheight = 0
vim.opt.showmode = false
vim.opt.ruler = false
vim.opt.fillchars = {
    horiz = " ",
    horizup = " ",
    horizdown = " ",
    vert = " ",
    vertleft = " ",
    vertright = " ",
    verthoriz = " ",
    eob = " ",
}

local function apply_ui_fixes()
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#000000", bg = "#000000" })
    vim.api.nvim_set_hl(0, "StatusLine", { fg = "#000000", bg = "#000000" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { fg = "#000000", bg = "#000000" })
end

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
    
    vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE", fg = "#555555" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#000000" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#000000", fg = "#555555" })
    vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE", fg = "#000000" })
    
    -- Refined Diagnostic Backgrounds
    vim.api.nvim_set_hl(0, "ErrorLineBG", { bg = "#260000" }) 
    vim.api.nvim_set_hl(0, "WarnLineBG",  { bg = "#262600" }) 
    vim.api.nvim_set_hl(0, "HintLineBG",  { bg = "#001526" }) 
    
    -- Diagnostic Text
    vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#ffaaaa", bg = "#000000", bold = true })
    vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#ffffaa", bg = "#000000", bold = true })
    vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#88ccff", bg = "#000000" })
    
    apply_ui_fixes()
end

vim.cmd('colorscheme pablo')
swap_pablo_blues()

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "TermOpen", "WinNew" }, {
    callback = apply_ui_fixes,
})

-- Full Line Background Logic with Severity Priority
local ns_diag_bg = vim.api.nvim_create_namespace("diagnostic_bg")
local function refresh_diagnostic_bg()
    if not vim.api.nvim_buf_is_valid(0) then return end
    vim.api.nvim_buf_clear_namespace(0, ns_diag_bg, 0, -1)
    
    local diagnostics = vim.diagnostic.get(0)
    local line_data = {}

    for _, diag in ipairs(diagnostics) do
        local lnum = diag.lnum
        local severity = diag.severity
        if not line_data[lnum] or severity < line_data[lnum] then
            line_data[lnum] = severity
        end
    end

    for lnum, severity in pairs(line_data) do
        local hl_group = "HintLineBG"
        if severity == vim.diagnostic.severity.ERROR then
            hl_group = "ErrorLineBG"
        elseif severity == vim.diagnostic.severity.WARN then
            hl_group = "WarnLineBG"
        end

        vim.api.nvim_buf_set_extmark(0, ns_diag_bg, lnum, 0, {
            line_hl_group = hl_group,
            number_hl_group = hl_group,
            priority = 10,
        })
    end
end

vim.api.nvim_create_autocmd("DiagnosticChanged", { callback = refresh_diagnostic_bg })

-- Clang execution
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
            refresh_diagnostic_bg()
        end
    })
    vim.opt_local.number = false
    vim.keymap.set('n', 'q', ':close<CR>', { buffer = clang_buf, silent = true })
    vim.cmd("normal! G")
end

-- Raylib execution
local function comp_prg()
    local file = vim.fn.expand("%:p")
    if file == "" then return end
    vim.cmd("silent w")
    local raw_cmd = string.format(
        "clang-20 %s -o main.out -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 -std=c23 -fcolor-diagnostics 2>&1 && ./main.out; rm main.out",
        vim.fn.shellescape(file)
    )
    vim.cmd("botright 15new")
    local bufnr = vim.api.nvim_get_current_buf()
    vim.fn.termopen({ "sh", "-c", raw_cmd })
    vim.opt_local.number = false
    vim.keymap.set('n', '<leader>q', ':close<CR>', { buffer = bufnr, silent = true })
    vim.keymap.set('t', 'jj', [[<C-\><C-n>]], { buffer = bufnr, silent = true })
    vim.cmd("startinsert")
end

-- Keymaps
vim.keymap.set({'i', 'v', 'x'}, 'jj', '<Esc>')
vim.keymap.set('t', 'jj', [[<C-\><C-n>]])
vim.keymap.set('n', '<leader>s', ':w<CR>')
pcall(vim.keymap.del, 'n', '<leader>q')
vim.keymap.set('n', '<leader>q', ':close<CR>', { silent = true })
vim.keymap.set('n', '<leader>d', run_clang_native)
vim.keymap.set('n', '<leader>r', comp_prg)
vim.keymap.set('n', '<leader>/', [[I// <Esc>==:s/^\s*\/\/ \/\/ //e<CR>]], { silent = true })
vim.keymap.set('v', '<leader>/', [[:norm I// <CR>_=:s/^\s*\/\/ \/\/ //e<CR>]], { silent = true })
-- LSP
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        vim.lsp.start({ name = "clangd", cmd = { "clangd" } })
    end,
})

-- Better Autocomplete behavior
vim.opt.shortmess:append("c")
vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert" }

-- Menu Navigation Mappings
vim.keymap.set('i', '<Tab>', function()
    return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true })

vim.keymap.set('i', '<S-Tab>', function()
    return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })

-- FIXED: Enter key accepts selection instead of inserting a newline when menu is open
vim.keymap.set('i', '<CR>', function()
    return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })

-- Instant popup on typing
vim.api.nvim_create_autocmd("InsertCharPre", {
    callback = function()
        if vim.fn.pumvisible() == 0 and vim.v.char:match("[%w_]") then
            local key = vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true)
            vim.api.nvim_feedkeys(key, "n", false)
        end
    end,
})

-- Diagnostic Config
vim.diagnostic.config({
    virtual_text = false,
    signs = false, 
    underline = true,
    update_in_insert = false,
})

-- Floating Window Logic
local last_row = -1
vim.api.nvim_create_autocmd("CursorMoved", {
    callback = function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        if row == last_row then return end
        last_row = row
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_config(win).relative ~= "" then
                vim.api.nvim_win_close(win, true)
            end
        end
        local diags = vim.diagnostic.get(0, { lnum = row - 1 })
        if #diags > 0 then
            vim.diagnostic.open_float(nil, {
                focusable = false,
                border = "single",
                scope = "line",
                header = "",
                prefix = "",
            })
        end
    end,
})

swap_pablo_blues()
