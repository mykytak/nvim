-- localize [undefined global vim] lsp msg
local vim = vim
local set = vim.opt

-----------------------
------- general -------
set.number = true
-- set.relativenumber = true
set.tabstop = 2
set.shiftwidth = 2
set.autoindent = true
set.smarttab = true
set.softtabstop = 2
-- set.listchars
-- converts tabs to spaces
set.expandtab = true
-- show tabs and trailing spaces
set.list = true
-- TODO not working?
set.mouse = a

vim.g.mapleader = ','
set.termguicolors = true
set.signcolumn = 'yes'

-- set.scrolloff = 999
set.inccommand = "split"

vim.opt.grepprg = "rg --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"

--------------------
------- lazy -------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

----------------------


----------------------
-------- lazy --------

local local_packages_path = os.getenv("NEOVIM_LOCAL_PLUGINS")

require("lazy").setup({
  dev = {
    path = local_packages_path,
  },
  spec = {
    'folke/tokyonight.nvim',
    {
      'nvim-treesitter/nvim-treesitter',
      build = ":TSUpdate",
    },
    -- comment stuff with gc
    {
      "folke/ts-comments.nvim",
      opts = {},
      event = "VeryLazy",
    },
    -- session (re)store and tracking
    'tpope/vim-obsession',
    'nvim-lualine/lualine.nvim',
    {
      'nvim-telescope/telescope.nvim',
      dependencies = { {'nvim-lua/plenary.nvim'} }
    },

    'preservim/nerdtree',
    -- use 'Tabular'
    'mattn/emmet-vim',
    -- buffer list with <Leader>b
    'jeetsukumaran/vim-buffergator',
    -- close buffers without closing split
    'qpkorr/vim-bufkill',
    {
      'vimwiki/vimwiki',
      init = function ()
        local path = os.getenv("NEOVIM_VIMWIKI_HOME") or "~/vimwiki"
        vim.g.vimwiki_list = {{
          path = path,
          syntax = 'markdown',
          ext = '.md'
        }}
      end
    },
    'nvim-tree/nvim-web-devicons',
    'neovim/nvim-lspconfig',
    'lspcontainers/lspcontainers.nvim',

    'mhinz/vim-signify',
    'kdheepak/lazygit.nvim',

    -- match and highlight brackets and control flow structures
    {
      'andymass/vim-matchup',
      init = function()
        vim.g.matchup_matchparen_offscreen = { method = "popup" }
      end
    },
    {
      "olimorris/codecompanion.nvim",
      opts = {},
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
      },
    },
    "othree/html5.vim",

    -- {
    --   'justinmk/vim-sneak',
    --   init = function()
    --     vim.g["sneak#label"] = 1
    --     vim.keymap.set("n", "f", "<Plug>Sneak_f")
    --     vim.keymap.set("n", "F", "<Plug>Sneak_F")
    --     vim.keymap.set("n", "t", "<Plug>Sneak_t")
    --     vim.keymap.set("n", "T", "<Plug>Sneak_T")
    --     -- vim.keymap.del("n", "<Plug>Sneak_s")
    --     -- vim.keymap.del("n", "<Plug>Sneak_S")
    --     -- vim.keymap.del("n", "<Plug>Sneak_,")
    --     vim.keymap.del("n", "s")
    --     vim.keymap.del("n", "S")
    --     vim.keymap.del("n", ",")
    --   end
    -- },

    {
      'nvim-orgmode/orgmode',
      event = 'VeryLazy',
      config = function()
        local path = os.getenv("NEOVIM_VIMWIKI_HOME") or "~/vimwiki"
        require('orgmode').setup({
          org_agenda_files = path .. '/**/*.org',
          org_default_notes_file = path .. '/refile.org',
          win_split_mode = "float",
        })
        vim.opt.conceallevel = 2
      end,
    },
    {
      "chipsenkbeil/org-roam.nvim",
      tag = "0.1.1",
      dependencies = {
        {
          "nvim-orgmode/orgmode",
          tag = "0.3.7",
        },
      },
      config = function()
        local path = os.getenv("NEOVIM_VIMWIKI_HOME") or "~/vimwiki"
        require("org-roam").setup({
          directory = path .. "/system/tasks"
        })
      end
    },
    {
      'smoka7/hop.nvim',
      version = "2.7.2",
      opts = {
        keys = 'etovxqpdygfblzhckisuran'
      },
      config = function()
        local hop = require("hop")
        hop.setup {}
        vim.keymap.set('n', 'gw', function()
          hop.hint_words()
        end)

        vim.keymap.set('n', 'gp', function()
          hop.hint_patterns()
        end)

        vim.keymap.set('n', 'gc', function()
          hop.hint_char1()
        end)

        -- local directions = require('hop.hint').HintDirection
        -- vim.keymap.set('', 'f', function()
        --   hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
        -- end, {remap=true})
        -- vim.keymap.set('', 'а', function()
        --   hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
        -- end, {remap=true})
        --
        -- vim.keymap.set('', 'F', function()
        --   hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
        -- end, {remap=true})
        -- vim.keymap.set('', 'А', function()
        --   hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
        -- end, {remap=true})
        --
        -- vim.keymap.set('', 't', function()
        --   hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
        -- end, {remap=true})
        -- vim.keymap.set('', 'е', function()
        --   hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
        -- end, {remap=true})
        --
        -- vim.keymap.set('', 'T', function()
        --   hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
        -- end, {remap=true})
        -- vim.keymap.set('', 'Е', function()
        --   hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
        -- end, {remap=true})
      end
    },
    "luizribeiro/vim-cooklang",
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      },
      keys = {
        {
          "<leader>?",
          function()
            require("which-key").show({ global = false })
          end,
          desc = "Buffer Local Keymaps (which-key)",
        },
      },
    },

    -- broken
    -- use 'lervag/vimtex'


    -------------------
    -- local plugins --
    { "wikiscripts", dev=true },
    { "local_lsp", dev=true },
    { "prioritizer", dev=true },
  }
})

----------------------
------- colors -------

require("tokyonight").setup({
  transparent = true,
  style = "night",
  on_colors = function(colors)
    colors.comment = "#567989"
  end,
  on_highlights = function(highlights, colors)
    highlights.LineNr     = { fg = "#5c7e8e" }

    highlights.DiffAdd    = { fg = "#20bf0f" }
    highlights.DiffChange = { fg = "#d8c83a" }
    highlights.DiffDelete = { fg = "#e84a5a" }
  end
})

vim.cmd [[colorscheme tokyonight]]


----------------------
------- remaps -------
-- disable :q and :x
vim.cmd [[cabbrev q <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'echo' : 'q')<CR>]]
vim.cmd [[cabbrev x <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'echo' : 'x')<CR>]]
-- wq should be just w
vim.keymap.set('c', 'wq', 'w', {remap=true})
-- disable accidental buffers/splits closing
vim.keymap.set('n', '<C-q>', '<nop>')
vim.keymap.set('n', '<C-w>q', '<nop>')
vim.keymap.set('n', '<C-w><C-q>', '<nop>')

-- fast movement
vim.keymap.set('', '<C-k>', '<C-u>')
vim.keymap.set('', '<C-j>', '<C-d>')

-- NERDTree
vim.keymap.set('n', '<Tab>', '<cmd>NERDTreeToggle<CR>')

-------------------------
------- telescope -------
local function telescope_setup()
  local telescope = require("telescope")

  telescope.setup()


  local builtin = require("telescope.builtin");
  vim.keymap.set('n', '<C-P>', builtin.find_files)
  vim.keymap.set('n', '<C-F>', builtin.live_grep)
  vim.keymap.set('n', '<C-B>', builtin.buffers)
end

telescope_setup()

-----------------------
------- lualine -------

require("lualine").setup {
  options = {
    theme = "tokyonight"
  }
}



--------------------------
------- treesitter -------

require'nvim-treesitter.configs'.setup {
  ensure_installed = { "rust", "bash", "c", "html", "vim", "vimdoc", "javascript", "markdown", "markdown_inline", "query", "vue", "astro", "blade", "comment", "make", "cmake", "cpp", "css", "csv", "diff", "dockerfile", "editorconfig", "gitcommit", "graphql", "haskell", "http", "json", "ledger", "lua", "nginx", "nix", "php", "phpdoc", "python", "regex", "ruby", "scss", "sql", "tmux", "toml", "typescript", "xml", "yaml", "odin", "c_sharp" },
  -- "latex", "lua_patterns",

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  indent = {
    enable = true,
  }
}

-- vim.opt.foldmethod = "manual"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"


-------------------------
------- lsp setup -------

require(".lsp")

-------------------------


----------------------
------- signify ------

vim.keymap.set('n', '<Leader>d', '<cmd>SignifyHunkDiff<CR>');

----------------------


----------------------
------- lazygit ------

vim.keymap.set('n', '<Leader>c', '<cmd>LazyGitCurrentFile<CR>')

----------------------


----------------------
--------- llm --------

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = "ollama",
    },
    inline = {
      adapter = "ollama",
    },
    cmd = {
      adapter = "ollama",
    },
  },
  adapters = {
    http = {
      opts = {
        show_default = false,
      },
      ollama = function ()
        return require("codecompanion.adapters").extend("ollama", {
          env = {
            url = "http://api.ollama.loc",
          },
          headers = {
            ["Content-Type"] = "application/json",
          },
          parameters = {
            sync = true,
          },
          schema = {
            model = {
              default = "gemma3:1b"
            },
          },
        })
      end,
    }
  }
})

---------------------
--- local plugins ---
require("wikiscripts").setup()

vim.keymap.set('n', '<Leader>s', "<cmd>WikiScriptsMakeLink<CR>")
vim.keymap.set('n', '<Leader>r', "<cmd>WikiScriptsRecalculateDay<CR>")

vim.keymap.set('n', 'gdn', "<cmd>WikiScriptsGoToNextDate<CR>")
vim.keymap.set('n', 'gdp', "<cmd>WikiScriptsGoToPrevDate<CR>")
vim.keymap.set('n', 'gtn', "<cmd>WikiScriptsGoToNextTime<CR>")
vim.keymap.set('n', 'gtp', "<cmd>WikiScriptsGoToPrevTime<CR>")


require("prioritizer").setup()

---------------=----
--- experimental ---


