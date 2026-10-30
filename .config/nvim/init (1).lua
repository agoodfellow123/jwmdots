vim.opt.errorformat = "%f:%l:%c: %t%*[^:]: %m"
--vim.opt.makeprg = "clang -Wall -Wextra -fcolor-diagnostics -fsyntax-only -std=c23 %"

vim.opt.termguicolors = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        -- Forcefully overwrite <leader>q for Normal mode
        vim.keymap.set('n', '<leader>q', ':close<CR>', { noremap = true, silent = true })
        
        -- Forcefully overwrite <leader>q for Terminal mode (so you don't have to hit jj)
        vim.keymap.set('t', '<leader>q', [[<C-\><C-n>:close<CR>]], { noremap = true, silent = true})
    end
})

local clang_buf = nil

local function run_clang_native()
    local file = vim.fn.expand("%:p")
    if file == "" then return end

    -- 1. Properly close the old buffer AND its window
    if clang_buf and vim.api.nvim_buf_is_valid(clang_buf) then
        vim.api.nvim_buf_delete(clang_buf, { force = true })
    end

    vim.cmd("silent w")
    
    -- Added a space before shellescape to prevent "clang: error: no such file"
    local cmd = "clang -Wall -Wextra -fcolor-diagnostics -fsyntax-only -std=c23 " .. vim.fn.shellescape(file)
    
    -- 2. Create the window
    vim.cmd("botright 10new")
    clang_buf = vim.api.nvim_get_current_buf()
    
    -- 3. Use termopen for better control in Lua
    vim.fn.termopen(cmd)

    -- 4. Apply settings to the SPECIFIC buffer we just created
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    
    -- Mapping 'q' locally so it doesn't break 'q' (recording) in your code
    vim.keymap.set('n', 'q', ':close<CR>', { buffer = clang_buf, silent = true })
    
    -- Auto-scroll to bottom
    vim.cmd("normal! G")
end

-- Map it to your shortcut
vim.keymap.set('n', '<leader>d', run_clang_native, { silent = true })

vim.opt_local.number = true
--vim.opt_local.relativenumber = true


-- Map it to your leader m
vim.keymap.set('n', '<leader>m', run_clang_native, { desc = "Run Clang with native colors" })

vim.keymap.set('t', 'jj', [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Press <leader>m to run clang and check for warnings
--vim.keymap.set('n', '<leader>m', ':make<CR>', { silent = true })

-- Save with Leader + s
vim.keymap.set('n', '<leader>s', ':w<CR>', { desc = "Save file and check warnings" })

vim.keymap.set({'i', 'v', 'x'}, 'jj', '<Esc>', { desc = "Exit visual mode" })
vim.opt.timeoutlen = 300

-- Navigate warnings easily
vim.keymap.set('n', ']q', ':cnext<CR>', { silent = true })
vim.keymap.set('n', '[q', ':cprev<CR>', { silent = true })

-- Toggle the list window
vim.keymap.set('n', '<leader>q', function()
    local qf_exists = false
    for _, win in pairs(vim.fn.getwininfo()) do
        if win["quickfix"] == 1 then qf_exists = true end
    end
    if qf_exists then vim.cmd('cclose') else vim.cmd('copen') end
end)

-- Create a group so the autocmd doesn't duplicate if you reload your config
--local clang_check_group = vim.api.nvim_create_augroup("ClangCheck", { clear = true })
--
--vim.api.nvim_create_autocmd("BufWritePost", {
--  group = clang_check_group,
--  pattern = { "*.c", "*.cpp", "*.h" }, -- Only run on C/C++ files
--  callback = function()
--    -- 'make!' (with exclamation) prevents jumping to the first error automatically
--    -- 'silent' prevents the "Press ENTER" prompt every time you save
--    vim.cmd("silent make!")
--    
--    -- Optional: Automatically open the quickfix window if there are errors
--    -- and close it if there are none.
--    local qf_list = vim.fn.getqflist()
--    if #qf_list > 0 then
--        vim.cmd("cwindow") -- Opens quickfix only if it contains errors
--    else
--        vim.cmd("cclose")  -- Closes it if you fixed everything
--    end
--  end,
--})
--
--Set the theme
--vim.cmd('colorscheme pablo')

local function swap_pablo_blues()
    -- Get all current highlights
    local highlights = vim.api.nvim_get_hl(0, {})

    for name, info in pairs(highlights) do
        -- 1. Check for 'blue' in different formats:
        -- info.fg == 255 is the decimal for standard Blue (#0000ff)
        -- info.ctermfg == 4 is the standard terminal Blue
        if info.fg == 255 or info.ctermfg == 4 or info.ctermfg == 12 then
            vim.api.nvim_set_hl(0, name, {
                fg = "#0088ff",
                bold = info.bold,
                italic = info.italic,
                underline = info.underline
            })
        end
    end
end

-- Apply the colorscheme first
vim.cmd('colorscheme pablo')

-- Run the swap immediately
swap_pablo_blues()

-- Ensure it persists if you manually reload the theme
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "pablo",
    callback = swap_pablo_blues,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "pablo",
    callback = function()
        local highlights = vim.api.nvim_get_hl(0, {})
        for name, info in pairs(highlights) do
            -- Pablo uses #0000ff (Blue) for many things
            if info.fg == 255 or info.ctermfg == 4 then 
                vim.api.nvim_set_hl(0, name, { fg = "#0044b2", bold = info.bold })
            end
        end
    end,
})

-- Hide the status bar
vim.opt.laststatus = 0

-- Optional: If you also want to hide the command line when not in use
-- This creates a very "Zen" or "Minimal" look
vim.opt.cmdheight = 0

-- Force syntax highlighting in the Quickfix window
vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function()
        vim.cmd("setlocal syntax=qf")
    end,
})


local function comp_prg()
    local file = vim.fn.expand("%:p")
    if file == "" then return end

    -- 1. Save the file
    vim.cmd("silent w")

    -- 2. Your specific shell command
    -- We use '&&' to ensure it only runs if compilation succeeds
local raw_cmd = string.format(
        "clang-20 %s -o main.out -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 -std=c23 -fcolor-diagnostics 2>&1 && ./main.out; rm main.out",
        vim.fn.shellescape(file)
    )

-- This is the bridge that prevents Neovim from choking on shell syntax
    local final_cmd = { "sh", "-c", raw_cmd }

vim.cmd("botright 15new")
    local bufnr = vim.api.nvim_get_current_buf()
    
    -- Pass the table to termopen so it executes cleanly
    vim.fn.termopen(final_cmd)

-- SAFETY: Only map <leader>q for NORMAL mode ('n')
    -- This prevents accidental closure while typing/interacting in the terminal.
    vim.keymap.set('n', '<leader>q', ':close<CR>', { buffer = bufnr, silent = true })

vim.keymap.set('t', '<leader>q', '<Nop>', { buffer = bufnr, silent = true })

    -- Ensure we have a way to get to Normal mode safely
    vim.keymap.set('t', 'jj', [[<C-\><C-n>]], { buffer = bufnr, silent = true })

    -- 5. UI Cleanup
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
vim.cmd("startinsert")
end

vim.keymap.set('n', '<leader>r', comp_prg, { desc = "Build and Run" })
