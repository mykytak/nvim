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
    'wbthomason/packer.nvim',

    'folke/tokyonight.nvim',
    {'ms-jpq/coq_nvim', branch='coq'},
    -- apparently required for NERDTree or smth
    -- use 'nvim-treesitter/nvim-treesitter'
    'tpope/vim-commentary',
    'tpope/vim-obsession',
    'ThePrimeagen/git-worktree.nvim',
    'nvim-lualine/lualine.nvim',
    {
      'nvim-telescope/telescope.nvim',
      dependencies = { {'nvim-lua/plenary.nvim'} }
    },

    'preservim/nerdtree',
    -- use 'Tabular'
    'mattn/emmet-vim',
    'jeetsukumaran/vim-buffergator',
    'qpkorr/vim-bufkill',
    {
      'vimwiki/vimwiki',
      init = function ()
        vim.g.vimwiki_list = {{ path = '~/vimwiki/', syntax = 'markdown', ext = '.md' }}
      end
    },
    'ryanoasis/vim-devicons',
    'neovim/nvim-lspconfig',
    'lspcontainers/lspcontainers.nvim',

    'mhinz/vim-signify',
    'kdheepak/lazygit.nvim',

    {
      'andymass/vim-matchup',
      init = function()
        -- may set any options here
        vim.g.matchup_matchparen_offscreen = { method = "popup" }
      end
    },

    -- broken
    -- use 'lervag/vimtex'
})


----------------------
-- general  plugins --

-- vimwiki
vim.g.vimwiki_list = {{ path = '~/vimwiki/', syntax = 'markdown', ext = 'md' }}


----------------------
------- colors -------
-- vim.g.tokyonight_transparent = true
-- vim.g.tokyonight_style = 'night'

-- vim.g.tokyonight_colors = {
--   LineNr,
--   comment = "#567989",
-- }

require("tokyonight").setup({
  transparent = true,
  style = "night",
  -- on_colors = function(colors)
  --   colors.linenr = "#567989"
  -- end
})

vim.g.tokyonight_colors = {
  comment = "#567989",
}

vim.cmd [[colorscheme tokyonight]]

vim.cmd [[hi LineNr guifg=#ff9e64 ctermbg=NONE]]

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



-------------------------
---------- COQ ----------

-- local vim.g.coq_settings.auto_start = true

--------------------------
------- treesitter -------
----- maybe some day -----

-- require'nvim-treesitter.configs'.setup {
--   ensure_installed = { "rust", "lua", "bash", "c" },

--   highlight = {
--     enable = true,
--     additional_vim_regex_highlighting = false,
--   },

--   indent = {
--     enable = true,
--   }
-- }

vim.opt.foldmethod = "manual"
-- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"


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

