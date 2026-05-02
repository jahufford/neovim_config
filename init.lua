vim.env.LANG = "en_US.UTF-8"
vim.env.LC_ALL = "en_US.UTF-8"
vim.env.LANGUAGE = "en_US.UTF-8"

vim.opt.rtp:prepend("~/.local/share/nvim/lazy/lazy.nvim")
-- case-insensitive search
vim.opt.ignorecase = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- jk → escape (insert mode)
vim.keymap.set("i", "jk", "<Esc>", { noremap = true })

-- jk → escape (visual mode)
vim.keymap.set("v", "jk", "<Esc>", { noremap = true })

-- jk → cancel command-line mode
vim.keymap.set("c", "jk", "<C-c>", { noremap = true })
vim.opt.timeoutlen = 300

vim.o.exrc = true    -- load .nvim.lua from current directory
vim.o.secure = true  -- but don't allow dangerous commands in them
vim.opt.formatoptions:remove({ "r", "o", "c" }) -- stop the annoying automatically adding comments
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o", "c" })
  end,
})

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})
vim.o.undofile = false
vim.o.scrolloff = 10
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.inccommand = 'split'
vim.opt.signcolumn = "yes"
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>') -- esc clear highlighting when searching with /
vim.opt.wrap = false


-- easier window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

vim.keymap.set("n", "<leader>cc", ":cclose<CR>", {desc="Close quick fix window"})  -- close quickfix

require("lazy").setup({
   {"stevearc/dressing.nvim"},
  -- LSP
  { "neovim/nvim-lspconfig" },
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls" },
      })
    end
  },

  -- completion engine
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },

  -- fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          winblend = 20,
        },
      })
    end,
  },
  { "kylechui/nvim-surround", opts = {} },

--  --treesitter
--{
--  'nvim-treesitter/nvim-treesitter',
--  lazy = false,
--  build = ':TSUpdate'
--},
  -- optional file tree
  { "nvim-tree/nvim-tree.lua" },
  {"uncleTen276/dark_flat.nvim"},
  { "Joakker/lua-json5" },
  { "mfussenegger/nvim-dap" },
  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
  { "folke/which-key.nvim", event = "VimEnter", opts = {} },
  { "nvim-lualine/lualine.nvim" },
  { "mbbill/undotree" },
})

      --local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'cpp','python','javascript', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
--require('nvim-treesitter').setup({
--    install = {
--        prefer_prebuilt = true,
--    }
--})
--require('nvim-treesitter').install { 'cpp', 'javascript', 'lua', 'bash', 'c','diff','html','luadoc','markdown','vim','vimdoc' }

vim.filetype.add({
  extension = {
    cpp = "cpp",
    hpp = "cpp",
    h   = "cpp",
  },
})

-- force filetype detection. the edr/src/main.cpp for some reason failed to detect as a cpp file and so clang wouldn't index it
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
  pattern = {"*.cpp", "*.hpp", "*.h", "*.c"},
  callback = function()
    vim.bo.filetype = "cpp"
  end,
})

-- set up nice status line
require("lualine").setup({
  options = {
    theme = "auto",
    component_separators = "|",
    section_separators = "",
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    lualine_c = { "filename" },
    lualine_x = { "diagnostics", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
})

vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("i", "<C-_>", "<Esc>gcc", { remap = true, desc = "Toggle comment" })

--require('nvim-treesitter').install { 'cpp', 'javascript', 'lua', 'python' }

vim.keymap.set("n", "<leader>fs", require("telescope.builtin").lsp_document_symbols, { desc = "Find symbols in file" })
vim.keymap.set("n", "<leader>fS", require("telescope.builtin").lsp_workspace_symbols, { desc = "Find symbols in workspace" })

vim.lsp.inlay_hint.enable(true)
vim.lsp.config("clangd", {
  -- your existing clangd config...
  settings = {
    clangd = {
      InlayHints = {
        Designators = true,
        Enabled = true,
        ParameterNames = true,
        DeducedTypes = true,
      },
    }
  }
})

vim.o.winborder = "rounded"
vim.o.winblend = 5

vim.keymap.set("n", "<leader>ih", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, {desc="Toggle inlay hints"})


vim.keymap.set("n", "<leader>lg", function()
  vim.cmd("tabnew | term lazygit")
  vim.cmd("startinsert")
end, {desc="LazyGit"})

vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle,{desc="Undo Tree"})

-- =========================
-- LSP (modern Neovim 0.11+ API)
-- =========================

local capabilities = require("cmp_nvim_lsp").default_capabilities()
function setup_clangd(opts)
  opts = opts or {}
  local default_opts = {
    cmd = {
      "clangd-20",
      "--background-index",
      "--clang-tidy",
      "--completion-style=detailed",
      "--header-insertion-decorators=0",
      "--pch-storage=memory",
      "--header-insertion=never",
      "--all-scopes-completion",
      "--limit-references=0",
      "--limit-results=0",
    },
    capabilities = capabilities,
  }
  -- merge opts into defaults
  local merged = vim.tbl_deep_extend("force", default_opts, opts)
  vim.lsp.config("clangd", merged)
  vim.lsp.enable("clangd")
end

--vim.lsp.enable("clangd")


local cmp = require("cmp")

cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),

  sources = {
    { name = "nvim_lsp" },
  },
})

require("nvim-tree").setup({
  hijack_netrw = true,
  view = {
    adaptive_size = true,
  },
  renderer = {
    highlight_git = true,
    highlight_opened_files = "icon",
  },
})

vim.keymap.set("n", "<leader>ft", ":NvimTreeToggle<CR>", {desc="Open File Tree"})

vim.keymap.set("n", "gd", vim.lsp.buf.definition, {desc="Goto Definition"})
vim.keymap.set("n", "<C-]>", vim.lsp.buf.definition, {desc="Goto Definition"})


vim.cmd.colorscheme("dark_flat")

vim.opt.termguicolors = true
vim.opt.background = "dark"

vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "#000000" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "#000000" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = "#000000", bg = "#000000" })
vim.api.nvim_set_hl(0, "LineNr", { fg = "#00FFFF", bg="#000000" })        -- current line number
--vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#FF00FF", bold = true })  -- other line numbers
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#FF0088", bold = true })  -- other line numbers
vim.opt.cursorline = true
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1a1a2e" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1c1c1c" })
vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#00FFFF", bg = "#1c1c1c" })
--vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#FF0000", bg = "#1c1c1c" })
--vim.api.nvim_set_hl(0, "Title", { fg = "#00AFFF" })
--vim.api.nvim_set_hl(0, "@markup.raw.markdown_inline", { fg = "#00AFFF" })
vim.api.nvim_set_hl(0, "Special", { fg = "#00AFFF" })


-- keywords (neon cyan)
--vim.api.nvim_set_hl(0, "Keyword", { fg = "#00FFFF", bold = true })
vim.api.nvim_set_hl(0, "Keyword", { fg = "#FF0000", bold = true })

-- functions (hot pink)
--vim.api.nvim_set_hl(0, "Function", { fg = "#FF0088" })
vim.api.nvim_set_hl(0, "Function", { fg = "#FFFF00" })

-- strings (acid green)
vim.api.nvim_set_hl(0, "String", { fg = "#39FF14" })

-- types (electric blue)
vim.api.nvim_set_hl(0, "Type", { fg = "#00AFFF" })

-- constants (amber)
vim.api.nvim_set_hl(0, "Constant", { fg = "#FFB000" })

-- comments (dim gray, not green garbage)
vim.api.nvim_set_hl(0, "Comment", { fg = "#666666", italic = true })


vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Run build in a terminal split at the bottom
local function build(clean)
  if not _G.build_targets or not _G.current_target then
    vim.notify("No build targets. Add a .nvim.lua to your project root.", vim.log.levels.ERROR)
    return
  end
  local cmd = _G.build_targets[_G.current_target]
  if clean then
      cmd = cmd .. " clean"
  end
  vim.cmd("botright 15split | term " .. cmd)
  vim.cmd("normal! G")
  local term_bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = term_bufnr,
    once = true,
    callback = function()
      local bufnr = term_bufnr
      vim.cmd("cgetbuffer " .. bufnr)
      vim.fn.timer_start(100, function()
          vim.cmd("bdelete! " .. bufnr)
          vim.cmd("botright 15copen")
          vim.cmd("normal! G") -- jump to bottom
          vim.notify("Build complete!", vim.log.levels.INFO)
        end)
    end,
  })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "<CR>", function()
      vim.cmd("cc " .. vim.fn.line("."))  -- jump to error
      vim.cmd("wincmd k")                 -- go to previous window (the file)
    end, { buffer = true })
  end,
})

vim.keymap.set("n", "]q", ":cnext<CR>")
vim.keymap.set("n", "[q", ":cprev<CR>")

---- Switch target interactively
--local function select_target()
--   if not _G.build_targets or vim.tbl_isempty(_G.build_targets) then
--    vim.notify("No build targets. Add a .nvim.lua to your project root.", vim.log.levels.ERROR)
--    return
--  end
--  local choices = vim.tbl_keys(_G.build_targets)
--  vim.ui.select(choices, {
--    prompt = "Select Build Target:",
--  }, function(choice)
--    if choice then
--      _G.current_target = choice
--      vim.notify("Build target: " .. choice, vim.log.levels.INFO)
--    end
--  end)
--end

local function select_target()
  if not _G.build_targets or vim.tbl_isempty(_G.build_targets) then
    vim.notify("No build targets. Add a .nvim.lua to your project root.", vim.log.levels.ERROR)
    return
  end
  local choices = vim.tbl_keys(_G.build_targets)
  vim.ui.select(choices, {
    prompt = "Select build target:",
    format_item = function(item)
      if item == _G.current_target then
        return "> " .. item
      else
        return "  " .. item
      end
    end,
  }, function(choice)
    if choice then
      _G.current_target = choice
      vim.notify("Build target: " .. choice, vim.log.levels.INFO)
    end
  end)
end


vim.keymap.set("n", "<leader>bt", select_target, {desc="Build: Select Target"})  -- "build target"
--vim.keymap.set("n", "<leader>bt", function() vim.notify("bt pressed") end)
vim.keymap.set("n", "<C-b>", function() build(false) end, { desc = "Build" })
vim.keymap.set("n", "<leader>bb", function() build(false) end, { desc = "Build" })
vim.keymap.set("n", "<leader>bc", function() build(true) end, { desc = "Clean Build" })

-- =========================
-- Terminal toggle
-- =========================
local term_buf = nil
local term_win = nil

local function toggle_terminal()
  -- If window is open, close it
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
    return
  end

  -- Open a bottom split
  vim.cmd("botright 15split")
  term_win = vim.api.nvim_get_current_win()

  -- Reuse existing terminal buffer if still alive
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    vim.api.nvim_win_set_buf(term_win, term_buf)
  else
    vim.cmd("term")
    term_buf = vim.api.nvim_get_current_buf()
  end

  -- Go into insert mode so you can type immediately
  vim.cmd("startinsert")
end

vim.keymap.set("n", "<C-t>", toggle_terminal, { desc = "Toggle Terminal" })
vim.keymap.set("n", "<leader>tt", toggle_terminal, { desc = "Toggle Terminal" })
vim.keymap.set("t", "<C-t>", function()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
  end
end, { desc = "Toggle Terminal" })
vim.keymap.set("t", "<leader>tt", function()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
  end
end, { desc = "Toggle Terminal" })

vim.keymap.set("n", "<leader>TT", function()
  vim.cmd("tabnew | term")
  vim.cmd("startinsert")
end, {desc="Toggle Fullscreen Terminal"})


-- Escape to get out of terminal insert mode without killing it
vim.keymap.set("t", "jk", "<C-\\><C-n>", {desc="Escape insert mode in Terminal"})


-- =========================
-- Telescope keymaps
-- =========================
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {desc="Fuzzy Find Files"})        -- fuzzy find files
vim.keymap.set("n", "<leader>fg", function()
  require("telescope.builtin").live_grep({
    default_text = vim.fn.expand("<cword>"),
  })
end,{desc="Live Grep"})
vim.keymap.set("n", "<leader>fw", require("telescope.builtin").grep_string,{desc="Grep word, Fuzzy Filter Results"})

vim.keymap.set("n", "<leader>fr", vim.lsp.buf.references, {desc="Find References"})    -- find all references
vim.keymap.set("n", "<C-g>", vim.lsp.buf.references, {desc="Find References"})    -- find all references

vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers,{desc="Show List of Buffers"})
require("telescope").setup({
  defaults = {
    mappings = {
      i = {
        ["<C-d>"] = require("telescope.actions").delete_buffer,
      },
      n = {
        ["<C-d>"] = require("telescope.actions").delete_buffer,
        ["dd"]    = require("telescope.actions").delete_buffer,
      },
    },
  },
})
vim.keymap.set('n','<leader>/', require("telescope.builtin").current_buffer_fuzzy_find,{desc="Current File Fuzzy Find"})
vim.keymap.set('n','<leader>/r', require("telescope.builtin").resume,{desc="Resume File Fuzzy Find"})



-- close current buffer
vim.keymap.set("n", "<leader>bd", ":bd<CR>", {desc="Close Current Buffer"})

-- close all buffers except current
vim.keymap.set("n", "<leader>bo", function()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local col = vim.api.nvim_win_get_cursor(0)[2]
  vim.cmd("%bd|e#|bd#")
  vim.api.nvim_win_set_cursor(0, {line, col})
end,{desc="Close All Buffer Except Current"})




-- =========================
-- LSP keymaps
-- =========================
vim.keymap.set("n", "K", vim.lsp.buf.hover)                  -- hover docs
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,{desc="Rename Symbol"})        -- rename symbol
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {desc="Code Actions"})   -- code actions (bonus, very useful)


-- =========================
-- Diagnostics / Problems panel
-- =========================
vim.keymap.set("n", "<leader>dp", vim.diagnostic.setqflist,{desc="Diagnostics: Open Errors and Warnings"})  -- all project diagnostics
vim.keymap.set("n", "<leader>df", vim.diagnostic.open_float,{desc="Diagnostics: Show Error for Current Line"}) -- error detail on current line
vim.keymap.set("n", "]d", vim.diagnostic.goto_next,{desc="Diagnostics: Jump to Previous Error"})          -- jump to next error
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev,{desc="Diagnostics: Jump to Next Error"})          -- jump to prev error


-- =========================
-- DAP (debugger)
-- =========================
local dap = require("dap")
local dapui = require("dapui")

--dapui.setup()
dapui.setup({
  mappings = {
    expand = { "<CR>", "<2-LeftMouse>" },
    open = "o",
    remove = "d",
    edit = "e",
    repl = "r",
    toggle = "t",
  },   
  layouts = {
    {
      elements = {
        { id = "breakpoints", size = 0.15 },
        { id = "scopes",      size = 0.40 },
        { id = "watches",     size = 0.20 },
        { id = "stacks",      size = 0.25 },
      },
      size = 40,
      position = "left",
    },
    {
      elements = {
        { id = "repl",    size = 1 },
        --{ id = "console", size = 0.5 },
      },
      size = 10,
      position = "bottom",
    },
  },
})
--dapui.setup({
--  icons = {
--    expanded = "v",
--    collapsed = ">",
--    current_frame = "*"
--  },
--  controls = {
--    icons = {
--      pause = "||",
--      play = ">",
--      step_into = "->",
--      step_over = "=>",
--      step_out = "<-",
--      step_back = "<<",
--      run_last = ">>",
--      terminate = "[]",
--    }
--  }
--})

-- open/close UI automatically when debug session starts/ends
dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_disconnect["dapui_config"] = function() dapui.close() end

require("dap").set_log_level("DEBUG")

dap.adapters.cppdbg = {
  type = "executable",
  command = "/home/jhufford/.local/share/nvim/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
  id = "cppdbg",
  options = {
    detached = false,
    initialize_timeout_sec = 30,
  },
  env = {
    LANG = "en_US.UTF-8",
    LC_ALL = "en_US.UTF-8",
  }
}

local function select_debug_config()
  if not _G.debug_configs or #_G.debug_configs == 0 then
    vim.notify("No debug configs. Add a .nvim.lua to your project root.", vim.log.levels.ERROR)
    return
  end
  local names = vim.tbl_map(function(c) return c.name end, _G.debug_configs)
  vim.ui.select(names, { prompt = "Select debug configuration:" }, function(choice)
    if not choice then return end
    for _, c in ipairs(_G.debug_configs) do
      if c.name == choice then
        _G.current_debug_config = c
        vim.notify("Debug config: " .. choice, vim.log.levels.INFO)
        break
      end
    end
  end)
end

--local current_debug_config = debug_configs[1]  -- local to the file, visible to all
                                                -- functions defined in the same file
--local function launch_debug()
--  if not current_debug_config then
--    vim.notify("No debug config loaded. Add a .nvim.lua to your project root.", vim.log.levels.ERROR)
--    return
--  end
--  local cfg = current_debug_config
--  local sshpass = "sshpass -p '" .. cfg.target_password .. "' "
--  local ssh = sshpass .. "ssh -o StrictHostKeyChecking=no " .. cfg.target_user .. "@" .. cfg.target_ip
--
--  vim.notify("Killing existing gdbserver...", vim.log.levels.INFO)
--  os.execute(ssh .. " 'killall gdbserver' 2>/dev/null")
--  os.execute(ssh .. " 'killall " .. vim.fn.fnamemodify(cfg.binary_remote, ":t") .. "' 2>/dev/null")
--
--  vim.notify("Starting gdbserver...", vim.log.levels.INFO)
--  os.execute(ssh .. " 'DISPLAY=:0.0 nohup gdbserver 0.0.0.0:" .. cfg.target_port .. " " .. cfg.binary_remote .. " > /tmp/gdbserver.log 2>&1 &'")
--
--  vim.defer_fn(function()
--    local check = os.execute(ssh .. " 'ps | grep [g]dbserver > /dev/null 2>&1'")
--    if check ~= 0 then
--      vim.notify("gdbserver failed to start! Check /tmp/gdbserver.log on target.", vim.log.levels.ERROR)
--      return
--    end
--
--    vim.notify("gdbserver running, connecting...", vim.log.levels.INFO)
--    require("dap").run({
--      name    = cfg.name,
--      type    = "cppdbg",
--      request = "launch",
--      program = cfg.binary_local,
--      miDebuggerPath = cfg.miDebuggerPath,
--      miDebuggerServerAddress = cfg.target_ip .. ":" .. cfg.target_port,
--      cwd     = "${workspaceFolder}",
--      stopAtEntry = false,
--      filterStderr = false,
--      filterStdout = false,
--      exceptionHandling = {
--        exceptionBreakpointFilters = {}
--      },
--      logging = {
--        engineLogging = false,
--        traceResponse = false,
--      },
--      setupCommands = {
--        {
--          description    = "Load .gdbinit",
--          text           = cfg.gdbinitPath,
--          ignoreFailures = true,
--        },
--        {
--          description    = "Enable pretty printing",
--          text           = "set print pretty on",
--          ignoreFailures = false,
--        },
--        {
--          description = "Enable dynamic pretty printing",
--          text = "-enable-pretty-printing",
--          ignoreFailures = false,
--        },
--      },
--    })
--  end, 2000)
--end
--local function launch_debug()
--  if not _G.current_debug_config then
--    vim.notify("No debug config loaded. Add a .nvim.lua to your project root.", vim.log.levels.ERROR)
--    return
--  end
--  local cfg = _G.current_debug_config
--
--  if cfg.type == "local" then
--    -- just connect dap directly, no gdbserver needed
--    require("dap").run({
--      name    = cfg.name,
--      type    = "cppdbg",
--      request = "launch",
--      program = cfg.binary_local,
--      cwd     = "${workspaceFolder}",
--      stopAtEntry = false,
--      MIMode = "gdb",
--      miDebuggerPath = cfg.miDebuggerPath,
--      filterStderr = false,
--      filterStdout = false,
--      exceptionHandling = {
--        exceptionBreakpointFilters = {}
--      },
--      logging = {
--        engineLogging = false,
--        traceResponse = false,
--      },
--      setupCommands = {
--        {
--          description    = "Load .gdbinit",
--          text           = "source " .. cfg.gdbinitPath,
--          ignoreFailures = true,
--        },
--        {
--          description    = "Enable pretty printing",
--          text           = "set print pretty on",
--          ignoreFailures = false,
--        },
--        {
--          description    = "Enable dynamic pretty printing",
--          text           = "-enable-pretty-printing",
--          ignoreFailures = false,
--        },
--      },
--    })
--  elseif cfg.type == "remote" then
--    -- existing remote gdbserver launch code
--    local sshpass = "sshpass -p '" .. cfg.target_password .. "' "
--    local ssh = sshpass .. "ssh -o StrictHostKeyChecking=no " .. cfg.target_user .. "@" .. cfg.target_ip
--
--    vim.notify("Killing existing gdbserver...", vim.log.levels.INFO)
--    os.execute(ssh .. " 'killall gdbserver' 2>/dev/null")
--    os.execute(ssh .. " 'killall " .. vim.fn.fnamemodify(cfg.binary_remote, ":t") .. "' 2>/dev/null")
--
--    vim.notify("Starting gdbserver...", vim.log.levels.INFO)
--    os.execute(ssh .. " 'DISPLAY=:0.0 nohup gdbserver 0.0.0.0:" .. cfg.target_port .. " " .. cfg.binary_remote .. " > /tmp/gdbserver.log 2>&1 &'")
--
--    vim.defer_fn(function()
--      local check = os.execute(ssh .. " 'ps | grep [g]dbserver > /dev/null 2>&1'")
--      if check ~= 0 then
--        vim.notify("gdbserver failed to start! Check /tmp/gdbserver.log on target.", vim.log.levels.ERROR)
--        return
--      end
--      vim.notify("gdbserver running, connecting...", vim.log.levels.INFO)
--      require("dap").run({
--        name    = cfg.name,
--        type    = "cppdbg",
--        request = "launch",
--        program = cfg.binary_local,
--        miDebuggerPath = cfg.miDebuggerPath,
--        miDebuggerServerAddress = cfg.target_ip .. ":" .. cfg.target_port,
--        cwd     = "${workspaceFolder}",
--        stopAtEntry = false,
--        filterStderr = false,
--        filterStdout = false,
--        exceptionHandling = {
--          exceptionBreakpointFilters = {}
--        },
--        logging = {
--          engineLogging = false,
--          traceResponse = false,
--        },
--        setupCommands = {
--          {
--            description    = "Load .gdbinit",
--            text           = "source " .. cfg.gdbinitPath,
--            ignoreFailures = true,
--          },
--          {
--            description    = "Enable pretty printing",
--            text           = "set print pretty on",
--            ignoreFailures = false,
--          },
--          {
--            description    = "Enable dynamic pretty printing",
--            text           = "-enable-pretty-printing",
--            ignoreFailures = false,
--          },
--        },
--      })
--    end, 2000)
--  else
--    vim.notify("Unknown debug config type: " .. tostring(cfg.type), vim.log.levels.ERROR)
--  end
--end

local function launch_debug()
  if not _G.current_debug_config then
    vim.notify("No debug config loaded. Add a .nvim.lua to your project root.", vim.log.levels.ERROR)
    return
  end
  local cfg = _G.current_debug_config

  -- build setup commands
  local setup_commands = {
    {
      description    = "Load .gdbinit",
      text           = "source " .. cfg.gdbinitPath,
      ignoreFailures = true,
    },
    {
      description    = "Enable pretty printing",
      text           = "set print pretty on",
      ignoreFailures = false,
    },
    {
      description    = "Enable dynamic pretty printing",
      text           = "-enable-pretty-printing",
      ignoreFailures = false,
    },
    {
      description = "Step into only known source",
      text = "set step-mode off",
      ignoreFailures = true,
    },
  }
  if cfg.extra_setup_commands then
    for _, cmd in ipairs(cfg.extra_setup_commands) do
      table.insert(setup_commands, cmd)
    end
  end

  if cfg.type == "local" then
    require("dap").run({
      name           = cfg.name,
      type           = "cppdbg",
      request        = "launch",
      program        = cfg.binary_local,
      cwd            = "${workspaceFolder}",
      stopAtEntry    = false,
      MIMode         = "gdb",
      miDebuggerPath = cfg.miDebuggerPath,
      filterStderr   = false,
      filterStdout   = false,
      exceptionHandling = {
        exceptionBreakpointFilters = {}
      },
      logging = {
        engineLogging = false,
        traceResponse = false,
      },
      setupCommands  = setup_commands,
    })
  elseif cfg.type == "remote" then
    local sshpass = "sshpass -p '" .. cfg.target_password .. "' "
    local ssh = sshpass .. "ssh -o StrictHostKeyChecking=no " .. cfg.target_user .. "@" .. cfg.target_ip
    vim.notify("Killing existing gdbserver...", vim.log.levels.INFO)
    os.execute(ssh .. " 'killall gdbserver' 2>/dev/null")
    os.execute(ssh .. " 'killall " .. vim.fn.fnamemodify(cfg.binary_remote, ":t") .. "' 2>/dev/null")
    vim.notify("Starting gdbserver...", vim.log.levels.INFO)
    local display = cfg.display and ("DISPLAY=" .. cfg.display .. " ") or ""
    os.execute(ssh .. " '" .. display .. "nohup gdbserver 0.0.0.0:" .. cfg.target_port .. " " .. cfg.binary_remote .. " > /tmp/gdbserver.log 2>&1 &'")
    vim.defer_fn(function()
      local check = os.execute(ssh .. " 'ps | grep [g]dbserver > /dev/null 2>&1'")
      if check ~= 0 then
        vim.notify("gdbserver failed to start! Check /tmp/gdbserver.log on target.", vim.log.levels.ERROR)
        return
      end
      vim.notify("gdbserver running, connecting...", vim.log.levels.INFO)
      require("dap").run({
        name                    = cfg.name,
        type                    = "cppdbg",
        request                 = "launch",
        program                 = cfg.binary_local,
        miDebuggerPath          = cfg.miDebuggerPath,
        miDebuggerServerAddress = cfg.target_ip .. ":" .. cfg.target_port,
        cwd                     = "${workspaceFolder}",
        stopAtEntry             = false,
        filterStderr            = false,
        filterStdout            = false,
        exceptionHandling = {
          exceptionBreakpointFilters = {}
        },
        logging = {
          engineLogging = false,
          traceResponse = false,
        },
        setupCommands = setup_commands,
      })
    end, 2000)
  else
    vim.notify("Unknown debug config type: " .. tostring(cfg.type), vim.log.levels.ERROR)
  end
end



-- =========================
-- Persistent breakpoints
-- =========================
local breakpoints_file = vim.fn.stdpath("data") .. "/breakpoints.json"
local loading_breakpoints = false

local function save_breakpoints()
  if loading_breakpoints then return end  -- don't save while loading
  local breakpoints = require("dap.breakpoints").get()
  local data = {}
  for bufnr, buf_bps in pairs(breakpoints) do
    local filename = vim.api.nvim_buf_get_name(bufnr)
    if filename ~= "" then
      local clean_bps = {}
      for _, bp in ipairs(buf_bps) do
        if bp.line and bp.line > 0 then  -- only save valid line numbers
          table.insert(clean_bps, {
            line          = bp.line,
            condition     = bp.condition,
            hit_condition = bp.hit_condition,
            log_message   = bp.log_message,
          })
        end
      end
      if #clean_bps > 0 then
        data[filename] = clean_bps
      end
    end
  end
  local file = io.open(breakpoints_file, "w")
  if file then
    file:write(vim.fn.json_encode(data))
    file:close()
  end
end

local function load_breakpoints()
  local file = io.open(breakpoints_file, "r")
  if not file then return end
  local content = file:read("*a")
  file:close()
  if not content or content == "" then return end
  local data = vim.fn.json_decode(content)
  if not data then return end
  loading_breakpoints = true  -- prevent save during load
  for filename, buf_bps in pairs(data) do
    local bufnr = vim.fn.bufadd(filename)
    vim.fn.bufload(bufnr)
    for _, bp in ipairs(buf_bps) do
      require("dap.breakpoints").set({
        condition     = bp.condition,
        hit_condition = bp.hit_condition,
        log_message   = bp.log_message,
      }, bufnr, bp.line)
    end
  end
  loading_breakpoints = false  -- re-enable saving
end

-- save breakpoints whenever they change
vim.api.nvim_create_autocmd("User", {
  pattern = "DapBreakpointSet",
  callback = save_breakpoints,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "DapBreakpointRemoved",
  callback = save_breakpoints,
})

-- also save when quitting just in case
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = save_breakpoints,
})

-- load breakpoints on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = load_breakpoints,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local breakpoints_data = io.open(breakpoints_file, "r")
    if not breakpoints_data then return end
    local content = breakpoints_data:read("*a")
    breakpoints_data:close()
    if not content or content == "" then return end
    local data = vim.fn.json_decode(content)
    if not data then return end
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if data[bufname] then
      for _, bp in ipairs(data[bufname]) do
        require("dap.breakpoints").set(bp, bufnr, bp.line)
      end
    end
  end,
})

-- manual save/load keymaps just in case
vim.keymap.set("n", "<leader>bs", save_breakpoints, {desc="Debug Save Breakpoints"})
vim.keymap.set("n", "<leader>bL", load_breakpoints, {desc="Debug Load Breakpoints"})

--local local_config = vim.fn.getcwd() .. "/.nvim.lua"
--if vim.fn.filereadable(local_config) == 1 then
--  vim.cmd("luafile " .. local_config)
--end


-- =========================
-- DAP keymaps
-- =========================
vim.keymap.set("n", "<leader>ds",       launch_debug, {desc = "Debug: Start"})
vim.keymap.set("n", "<leader>dc", select_debug_config, {desc = "Debug: Select Config"})  -- switch debug config

vim.keymap.set("n", "<F8>",  dap.continue)           -- start/continue
vim.keymap.set("n", "<F6>", dap.step_over)          -- step over
vim.keymap.set("n", "<F5>", dap.step_into)          -- step into
vim.keymap.set("n", "<F7>", dap.step_out)           -- step out
--vim.keymap.set("n", "<leader>bp",  dap.toggle_breakpoint)  -- toggle breakpoint
vim.keymap.set("n", "<leader>db", function() 
  dap.toggle_breakpoint()
  save_breakpoints()
end, {desc="Debug: Toggle Breakpoint"})  -- toggle breakpoint
vim.keymap.set("n", "<F9>", function() 
  dap.toggle_breakpoint()
  save_breakpoints()
end)  -- toggle breakpoint
--vim.keymap.set("n", "<leader>dr", dap.repl.open, {desc="Debug: Open Repl"})     -- debug console
vim.keymap.set("n", "<leader>du", dapui.toggle, {desc="Debug: Toggile Dap UI"})      -- toggle UI manually
vim.keymap.set("n", "<leader>dx", dap.terminate, {desc="Debug: Terminate"})     -- stop debugging
vim.keymap.set("n", "<leader>dbc", function()         -- conditional breakpoint
  dap.set_breakpoint(vim.fn.input("Condition: "))
end, {desc="Debug: Conditional Breakpoint"})
vim.keymap.set("n", "<leader>dw", function()
  dapui.elements.watches.add(vim.fn.expand("<cword>"))
end, {desc="Debug: Add Watch"})

vim.keymap.set("n", "<leader>dl", dap.run_to_cursor, {desc="Debug: Run to Line"})   -- debug run to Line


--vim.keymap.set("n", "<leader>ds", function()
--  local session = require("dap").session()
--  if not session then
--    vim.notify("No active debug session", vim.log.levels.WARN)
--    return
--  end
--  local word = vim.fn.expand("<cword>")
--  local prev_win = vim.api.nvim_get_current_win()  -- save current window
--  local hover = require("dap.ui.widgets").hover()
--  vim.keymap.set("n", "q", function()
--    hover.close()
--    vim.api.nvim_set_current_win(prev_win)  -- restore focus
--  end, { buffer = true, nowait = true })
--  vim.ui.input({ prompt = "set variable ", default = word .. " = " }, function(expr)
--    if not expr then
--      hover.close()
--      vim.api.nvim_set_current_win(prev_win)
--      return
--    end
--    local frameId = session.current_frame and session.current_frame.id
--    session:request("evaluate", {
--      expression = "-exec set variable " .. expr,
--      context = "repl",
--      frameId = frameId,
--    }, function(err)
--      hover.close()
--      vim.schedule(function()
--        vim.api.nvim_set_current_win(prev_win)  -- restore focus
--      end)
--      if err then
--        vim.notify("Error: " .. vim.inspect(err), vim.log.levels.ERROR)
--      else
--        vim.notify("set variable " .. expr, vim.log.levels.INFO)
--      end
--    end)
--  end)
--end, { desc = "Debug: Set Variable" })

require("debug_vars").open()
vim.keymap.set("n", "<leader>dv", function()
  require("debug_vars").open()
end)

-- show value of variable when you have the cursor on it
vim.keymap.set("n", "<leader>dh", function()
  local widgets = require("dap.ui.widgets")
  local hover = widgets.hover()
  -- map q to close the hover window
  vim.keymap.set("n", "q", function()
    hover.close()
  end, { buffer = true })
  vim.keymap.set("n", "jk", function()
    hover.close()
  end, { buffer = true })
end, {desc="Debug: Show Variable"})

-- this shows the value as a notification in the bottom
--vim.keymap.set("n", "<leader>dh", function()
--  local session = require("dap").session()
--  if not session then
--    vim.notify("No active debug session", vim.log.levels.WARN)
--    return
--  end
--  local word = vim.fn.expand("<cword>")
--  local frame = session.current_frame
--  if not frame then
--    vim.notify("No current frame", vim.log.levels.WARN)
--    return
--  end
--  session:request("evaluate", {
--    expression = word,
--    context = "hover",
--    frameId = frame.id,
--  }, function(err, response)
--    if err then
--      vim.notify("Error: " .. vim.inspect(err), vim.log.levels.ERROR)
--    elseif response then
--      vim.notify(word .. " = " .. response.result, vim.log.levels.INFO)
--    end
--  end)
--end)




-- ----------------------------------
-- New Project Stuff
-- ----------------------------------
-- =========================
-- Project scaffolding
-- =========================
local function get_project_name()
  return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
end

local function create_file(path, contents)
  -- create parent directories if needed
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local file = io.open(path, "w")
  if file then
    file:write(contents)
    file:close()
  else
    vim.notify("Failed to create: " .. path, vim.log.levels.ERROR)
  end
end

local function new_project()
  local saved_autoread = vim.opt.autoread:get()
  vim.opt.autoread = true -- auto reload files that have changed out of neovim wihtout asking

  local proj = get_project_name()
  local pwd = vim.fn.getcwd()

  -- .ignore
  create_file(".ignore", [[
build/
.git/
]])

  -- .nvim.lua
  create_file(".nvim.lua", string.format([[
-- =========================
-- Build system
-- =========================
_G.build_targets = {
  debug   = "bash scripts/build_debug.sh",
  release = "bash scripts/build_release.sh",
  local_tests = "bash scripts/build_local_tests.sh",
}
_G.current_target = "debug"  -- default
-- =========================
-- Debug configurations
-- =========================
_G.debug_configs = {
  {
    name          = "%s",
    type          = "local",
    binary_local  = "%s/build/Debug/bin/%s",
    gdbinitPath   = "%s/.gdbinit",
    miDebuggerPath = "/usr/bin/gdb",
  },
}
_G.current_debug_config = debug_configs[1]
setup_clangd({
  cmd = {
    "clangd-20",
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
    "--header-insertion-decorators=0",
    "--pch-storage=memory",
    "--header-insertion=never",
    "--all-scopes-completion",
    "--limit-references=0",
    "--limit-results=0",
  },
})
vim.keymap.set("n", "<leader>fg", function()
  require("telescope.builtin").live_grep({
    default_text = vim.fn.expand("<cword>"),
    search_dirs = {
      "%s",
    },
  })
end)
]], proj, pwd, proj, pwd, pwd))

  -- CMakeLists.txt (root)
  create_file("CMakeLists.txt", string.format([[
cmake_minimum_required(VERSION 3.23)
project(%s)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Default build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release")
endif()
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
add_subdirectory(src)
add_subdirectory(tests/local_tests)
install(TARGETS %s RUNTIME DESTINATION bin)
install(TARGETS local_tests RUNTIME DESTINATION bin)
install(FILES $<TARGET_FILE:%s>.debug DESTINATION bin OPTIONAL)
]], proj, proj, proj))

 -- src/CMakeLists.txt
  create_file("src/CMakeLists.txt", string.format([[
add_compile_definitions(
)

add_library(%s_lib STATIC)

target_sources(%s_lib
    PRIVATE
        %s.cpp
)

target_compile_features(%s_lib PUBLIC cxx_std_23)

target_include_directories(%s_lib
    PUBLIC
        .
)

target_link_libraries(%s_lib
    PRIVATE
)

target_compile_options(%s_lib PRIVATE
    $<$<CONFIG:Debug>:-O0 -g3 -Wno-narrowing -Wno-psabi>
    $<$<CONFIG:Release>:-Os -g3 -ffunction-sections -fdata-sections -fno-omit-frame-pointer -Wno-narrowing -Wno-psabi>
)

add_executable(%s)

target_compile_options(%s PRIVATE
    $<$<CONFIG:Debug>:-O0 -g3 -Wno-narrowing -Wno-psabi>
    $<$<CONFIG:Release>:-Os -g3 -ffunction-sections -fdata-sections -fno-omit-frame-pointer -Wno-narrowing -Wno-psabi>
)

target_sources(%s
    PRIVATE
        main.cpp
)

target_include_directories(%s
    PUBLIC
        .
)

target_link_libraries(%s
    PRIVATE
        %s_lib
)

target_compile_features(%s PRIVATE cxx_std_23)

target_link_options(%s PRIVATE
    $<$<CONFIG:Release>:-Wl,--gc-sections -Wl,--as-needed>
)

if(UNIX AND NOT APPLE)
    if(NOT CMAKE_OBJCOPY OR NOT CMAKE_STRIP)
        message(WARNING "CMAKE_OBJCOPY or CMAKE_STRIP not set, skipping debug split")
    elseif(CMAKE_CONFIGURATION_TYPES)
        add_custom_command(TARGET %s POST_BUILD
            COMMAND sh -c "$<IF:$<CONFIG:Release>,${CMAKE_OBJCOPY} --only-keep-debug $<TARGET_FILE:%s> $<TARGET_FILE:%s>.debug,:>"
            COMMAND sh -c "$<IF:$<CONFIG:Release>,${CMAKE_STRIP} --strip-debug --strip-unneeded $<TARGET_FILE:%s>,:>"
            COMMAND sh -c "$<IF:$<CONFIG:Release>,${CMAKE_OBJCOPY} --add-gnu-debuglink=$<TARGET_FILE:%s>.debug $<TARGET_FILE:%s>,:>"
        )
    else()
        if(CMAKE_BUILD_TYPE STREQUAL "Release")
            add_custom_command(TARGET %s POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E echo "Splitting debug symbols..."
                COMMAND ${CMAKE_OBJCOPY} --only-keep-debug $<TARGET_FILE:%s> $<TARGET_FILE:%s>.debug
                COMMAND ${CMAKE_STRIP} --strip-debug --strip-unneeded $<TARGET_FILE:%s>
                COMMAND ${CMAKE_OBJCOPY} --add-gnu-debuglink=$<TARGET_FILE:%s>.debug $<TARGET_FILE:%s>
                COMMENT "Stripping and splitting debug info for %s"
            )
        endif()
    endif()
endif()
]],
    proj, proj, proj, proj, proj, proj, proj,
    proj, proj, proj, proj, proj, proj, proj, proj,
    proj, proj, proj, proj, proj, proj,
    proj, proj, proj, proj, proj, proj, proj))


  -- src/new_proj.h
  local guard = proj:upper() .. "_H"
  create_file(string.format("src/%s.h", proj), string.format([[
#ifndef %s
#define %s
#include "common_headers.h"
int %s(int argc, char* argv[]);
#endif
]], guard, guard, proj))

  -- src/new_proj.cpp
  create_file(string.format("src/%s.cpp", proj), string.format([[
#include "common_headers.h"
int %s(int argc, char* argv[])
{
    cout << "Hello world!" << endl;
    return 0;
}
]], proj))

  -- src/common_headers.h
  create_file("src/common_headers.h", [[
#include <iostream>
#include <cstdint>
#include <string>
#include <vector>
#include <sstream>
#include <expected>
using std::cout;
using std::endl;
using std::string;
using std::vector;
using std::stringstream;
using std::expected;
using std::unexpected;
]])

create_file("scripts/build_debug.sh", [==[
#!/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
JOBS=3
TARGET=all
if [[ -n "$1" ]]; then
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        JOBS="$1"
        TARGET="${2:-all}"
    else
        TARGET="$1"
    fi
fi
cmake -B "$PROJECT_DIR/build/Debug" -S "$PROJECT_DIR" -DCMAKE_BUILD_TYPE=Debug
cmake --build "$PROJECT_DIR/build/Debug" -j"$JOBS" --target "$TARGET"
]==])

  -- scripts/build_release.sh
  create_file("scripts/build_release.sh", [==[
#!/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
JOBS=3
TARGET=all
if [[ -n "$1" ]]; then
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        JOBS="$1"
        TARGET="${2:-all}"
    else
        TARGET="$1"
    fi
fi
cmake -B "$PROJECT_DIR/build/Release" -S "$PROJECT_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$PROJECT_DIR/build/Release" -j"$JOBS" --target "$TARGET"
]==])

  -- scripts/build_local_tests.sh
  create_file("scripts/build_local_tests.sh", [[
#!/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cmake -B "$PROJECT_DIR/build/local_tests" -S "$PROJECT_DIR/tests/local_tests" -DCMAKE_BUILD_TYPE=Debug
cmake --build "$PROJECT_DIR/build/local_tests" -j3 --target ${1:-all}
]])

  -- make scripts executable
  os.execute("chmod +x scripts/build_debug.sh scripts/build_release.sh scripts/build_local_tests.sh")

  -- tests/local_tests/CMakeLists.txt
  create_file("tests/local_tests/CMakeLists.txt", [[
cmake_minimum_required(VERSION 3.23...3.27)
project(local_tests)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Default build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release")
endif()
add_executable(local_tests)
target_compile_options(local_tests PRIVATE
    -O0 -g3 -Wno-psabi
)
target_sources(local_tests
    PRIVATE
        local_tests.cpp
)
target_include_directories(local_tests
    PUBLIC
        .
        ../
)
target_compile_features(local_tests PRIVATE cxx_std_14)
target_link_options(local_tests PRIVATE
    $<$<CONFIG:Release>:-Wl,--gc-sections -Wl,--as-needed>
)
]])

  -- tests/local_tests/local_tests.cpp
  create_file("tests/local_tests/local_tests.cpp", [[
#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest.h>
int factorial(int number) { return number <= 1 ? number : factorial(number - 1) * number; }
TEST_CASE("testing the factorial function") {
    CHECK(factorial(1) == 1);
    CHECK(factorial(2) == 2);
    CHECK(factorial(3) == 6);
    CHECK(factorial(10) == 3628800);
}
]])

-- .clangd
  create_file(".clangd", string.format([[
# .clangd file at %s
CompileFlags:
  CompilationDatabase: %s/build/Debug
  Compiler: g++
  Add:
    #- --query-driver=
    #- --target=x86_64-linux-gnu
    #- -std=c++17
    #- -nostdinc++
    #- -isystem
  Remove:
    - --sysroot=*
    - -march=*
    - -mthumb
    - -mfpu=*
    - -mfloat-abi=*
# Optional: extra flags
# Add:
#   - -I/path/to/extra/includes
]], pwd, pwd))


  -- src/main.cpp
  create_file("src/main.cpp", string.format([[
#include "%s.h"
int main(int argc, char* argv[])
{
    return %s(argc, argv);
}
]], proj, proj))


  -- download doctest
  vim.notify("Downloading doctest...", vim.log.levels.INFO)
  os.execute("curl -sL https://raw.githubusercontent.com/doctest/doctest/master/doctest/doctest.h -o tests/doctest.h")
  -- copy to local_tests dir so it's accessible
  os.execute("cp tests/doctest.h tests/local_tests/doctest.h")

  vim.notify("Project '" .. proj .. "' created!", vim.log.levels.INFO)

  -- trust and load the .nvim.lua
  vim.cmd("luafile .nvim.lua")

  -- open main file
  vim.cmd("edit src/main.cpp")

    -- trigger first build to generate compile_commands.json
  vim.notify("Running initial build...", vim.log.levels.INFO)
  vim.cmd("botright 15split | term bash scripts/build_debug.sh")
  vim.cmd("normal! G")

  local build_buf = vim.api.nvim_get_current_buf()
  vim.defer_fn(function()
    vim.cmd("wincmd k")
    vim.cmd("edit src/main.cpp")
    vim.cmd("bdelete! " .. build_buf)
    vim.defer_fn(function()
      vim.cmd("lsp restart")
      vim.notify("Project ready!", vim.log.levels.INFO)
    end, 500)
    vim.defer_fn(function()
      vim.opt.autoread = saved_autoread
    end, 5000)
  end, 5000)
end

local function new_header()
  vim.ui.input({ prompt = "Header name: " }, function(name)
    if not name or name == "" then return end
    local guard = name:upper():gsub("%.", "_"):gsub("/", "_") .. "_H"
    local path = "src/" .. name .. ".h"
    create_file(path, string.format([[
#ifndef %s
#define %s

#endif // %s
]], guard, guard, guard))
    vim.cmd("edit " .. path)
    vim.notify("Created " .. path, vim.log.levels.INFO)
  end)
end

local function new_cpp_pair()
  vim.ui.input({ prompt = "Class/file name: " }, function(name)
    if not name or name == "" then return end
    local guard = name:upper():gsub("%.", "_"):gsub("/", "_") .. "_H"
    local hpath = "src/" .. name .. ".h"
    local cpath = "src/" .. name .. ".cpp"
    create_file(hpath, string.format([[
#ifndef %s
#define %s
#include "common_headers.h"

#endif // %s
]], guard, guard, guard))
    create_file(cpath, string.format([[
#include "%s.h"

]], name))
    vim.cmd("edit " .. hpath)
    vim.notify("Created " .. hpath .. " and " .. cpath, vim.log.levels.INFO)
  end)
end

vim.keymap.set("n", "<leader>pn", new_project,  { desc = "New project scaffold" })
vim.keymap.set("n", "<leader>ph", new_header,   { desc = "New header file" })
vim.keymap.set("n", "<leader>pc", new_cpp_pair, { desc = "New cpp+header pair" })

