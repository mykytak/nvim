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
------- packer -------
-- vim.cmd [[packadd packer.nvim]]
-- vim.cmd [[packloadall]]

-- return require('packer').startup(
require("lazy").setup({
    -- unmaintained. And I'm using lazy anyway, why I need packer?
    -- 'wbthomason/packer.nvim', 

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

    -- broken
    -- use 'lervag/vimtex'

    -- {
    --   "vhyrro/luarocks.nvim",
    --   priority=1000,
    --   config = true,
    -- },
    -- {
    --   "nvim-neorg/neorg",
    --   dependencies = { "luarocks.nvim" },
    --   lazy = false,
    --   version = "*",
    --   ft = "norg",
    --   config = function()
    --     require("neorg").setup({
    --       load = {
    --         ["core.defaults"] = {},
    --         ["core.dirman"] = {
    --           config = {
    --             workspaces = {
    --             }
    --           }
    --         },
    --         ["core.integrations"] = {
    --           config = {
    --             disable = { "treesitter" }
    --           }
    --         }
    --       }
    --     })
    --   end
    -- }
})


----------------------
-- general  plugins --

-- vimwiki
vim.g.vimwiki_list = {{ path = '~/vimwiki/', syntax = 'markdown', ext = 'md' }}


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
vim.api.nvim_set_keymap('c', 'wq', 'w', {})
-- disable accidental buffers/splits closing
vim.api.nvim_set_keymap('n', '<C-q>', '<nop>', { noremap  = true })
vim.api.nvim_set_keymap('n', '<C-w>q', '<nop>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-w><C-q>', '<nop>', { noremap = true })

-- fast movement
vim.api.nvim_set_keymap('', '<C-k>', '<C-u>', { noremap = true })
vim.api.nvim_set_keymap('', '<C-j>', '<C-d>', { noremap = true })

-- NERDTree
vim.cmd [[ nnoremap <Tab> :NERDTreeToggle<CR> ]]

-------------------------
------- telescope -------
local telescope = require("telescope")

telescope.setup(
)

-- telescope.load_extension("git_worktree")


vim.api.nvim_set_keymap('n', '<C-P>', "<cmd>lua require('telescope.builtin').find_files()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<C-F>', "<cmd>lua require('telescope.builtin').live_grep()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<C-B>', "<cmd>lua require('telescope.builtin').buffers()<CR>", { noremap = true })
-- vim.api.nvim_set_keymap('n', '<C-T>', "<cmd>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>", { noremap = true })

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
  ensure_installed = { "rust", "bash", "c", "html", "vim", "vimdoc", "javascript", "markdown", "markdown_inline", "query", "vue", "astro", "blade", "comment", "make", "cmake", "cpp", "css", "csv", "diff", "dockerfile", "editorconfig", "gitcommit", "graphql", "haskell", "http", "json", "ledger", "lua", "nginx", "nix", "norg", "php", "phpdoc", "python", "regex", "ruby", "scss", "sql", "tmux", "toml", "typescript", "xml", "yaml", "odin" },
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

vim.api.nvim_set_keymap('n', '<Leader>d', '<cmd>SignifyHunkDiff<CR>', {})

----------------------


----------------------
------- lazygit ------

vim.api.nvim_set_keymap('n', '<Leader>c', '<cmd>LazyGitCurrentFile<CR>', {})

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
})

----------------------


require(".wikiscripts")

vim.api.nvim_set_keymap('n', '<Leader>s', "<cmd>WikiScriptsFillBuffers<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>r', "<cmd>WikiScriptsRecalculateDay<CR>", { noremap = true })


