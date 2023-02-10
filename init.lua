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


----------------------
-- general  plugins --

-- vimwiki
vim.g.vimwiki_list = {{ path = '~/vimwiki/', syntax = 'markdown', ext = '.md' }}


----------------------
------- colors -------
vim.g.tokyonight_transparent = true
vim.g.tokyonight_style = 'night'

vim.g.tokyonight_colors = {
  LineNr,
  comment = "#567989",
}

vim.cmd [[colorscheme tokyonight]]

vim.cmd [[hi LineNr guifg=#ff9e64 ctermbg=NONE]]

----------------------
------- remaps -------
-- disable :q and :x
vim.cmd [[cabbrev q <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'echo' : 'q')<CR>]]
vim.cmd [[cabbrev x <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'echo' : 'x')<CR>]]
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

telescope.load_extension("git_worktree")


vim.api.nvim_set_keymap('n', '<C-P>', "<cmd>lua require('telescope.builtin').find_files()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<C-F>', "<cmd>lua require('telescope.builtin').live_grep()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<C-B>', "<cmd>lua require('telescope.builtin').buffers()<CR>", { noremap = true })
vim.api.nvim_set_keymap('n', '<C-T>', "<cmd>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>", { noremap = true })

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

local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)

local nvim_lsp = require'lspconfig'
local containers = require'lspcontainers'
local lsp_util = require'lspconfig.util'
local coq      = require'coq'

local on_attach = function(client)
  vim.api.nvim_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', {})
  vim.api.nvim_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', {})
  vim.api.nvim_set_keymap('n', '<C-Space>', '<cmd>lua vim.lsp.buf.hover()<CR>', {})

  -- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  -- map('n', 'K',  '<cmd>lua vim.lsp.buf.hover()<CR>', {})
  -- map('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()', {})
end

local skip_local_images = true

function get_project_image(lang, fname)
  local root_dir = lsp_util.root_pattern '.lspconf'(fname)

  -- return lang related image, not static one
  local default_image = "lspcontainers/rust-analyzer"

  if skip_local_images then
    return default_image
  end

  if type(root_dir) == "nil" then
    return default_image
  end

  local local_config = {}
  local f, err = loadfile(root_dir .. "/.lspconf", "t", local_config)

  if f then
    f()
    vim.notify("[LSP_IMAGE DEBUG] local image loaded: " .. local_config.image)

    -- cfg.cmd = containers.command(local_config.image, {
    --   network = "bridge",
    -- }),

    return local_config.image
  end

  return default_image
end

function ensure_image_exists(cfg)
  if skip_local_images then
    return cfg
  end

  -- local settings = {
  --   image = "required",
  --   dockerfile = "optinal"
  -- }

  -- I should hijack into LspStart

  local fname = vim.api.nvim_buf_get_name(0)
  local root_dir = lsp_util.root_pattern '.lspconf'(fname)

  if type(root_dir) == "nil" then
    vim.notify("[LSP_IMAGE DEBUG] no local config for " .. fname, vim.log.levels.DEBUG)
    return cfg
  end

  vim.notify("[LSP_IMAGE DEBUG] root dir found: " .. root_dir, vim.log.levels.DEBUG)

  local local_config = {}
  local f, err = loadfile(root_dir .. "/.lspconf", "t", local_config)

  if f then
    f()
    vim.notify("[LSP_IMAGE DEBUG] local image loaded: " .. local_config.image)

    -- cfg.cmd = containers.command(local_config.image, {
    --   network = "bridge",
    -- }),
  else
    print(err)
  end

  return cfg

  -- so I need my own basic lsp container
  -- so I can branch from it with additional things

  -- wrapper around lsp containers (cmd)
  -- aimed to build image for a specific project (if necessary)
  --
  -- I'll need image name here,
  -- and if image do not exist or need to be rebuilded,
  -- then I should build it.
  -- gotta check how(if) I can run build in separate thread/process
  --
  -- Build it from Dockerfile in project root or from provided path
  --
  -- for now it could be just some sort of project-related config
  -- with image tag being passed to containers.command
end

nvim_lsp.rust_analyzer.setup(
  coq.lsp_ensure_capabilities(
    ensure_image_exists {
      on_attach = on_attach,
      cmd = containers.command('rust_analyzer', {
        network = "bridge",
        image = get_project_image('rust', vim.api.nvim_buf_get_name(0))
      }),
      settings = {
        ["rust-analyzer"] = {
          imports = {
            granularity = {
              groups = "module"
            },
            prefix = "self",
          },
          cargo = {
            buildScripts = {
              enable = true
            }
          },
          procMacro = {
            enable = true
          }
        }
      },

      -- get root_dir from container because there's no cargo in host
      root_dir = function(fname)
        local cargo_crate_dir = lsp_util.root_pattern 'Cargo.toml'(fname)
        local cmd = containers.command('rust-analyzer', {
          image = get_project_image('rust', fname),
          cmd_builder = function(runtime, workdir, image, network, docker_volume)
            local docker_cmd = { 'cargo', 'metadata', '--no-deps', '--format-version', '1' }

            local mnt_volume
            if docker_volume ~= nil then
              mnt_volume ="--volume="..docker_volume..":"..workdir..":z"
            else
              mnt_volume = "--volume="..workdir..":"..workdir..":z"
            end


            return {
              runtime,
              "container",
              "run",
              "--interactive",
              "--rm",
              "--network="..network,
              "--workdir="..workdir,
              mnt_volume,
              image,
              unpack(docker_cmd)
            }
          end
        })
        local cargo_metadata = ''
        local cargo_metadata_err = ''
        local cm = vim.fn.jobstart(table.concat(cmd, ' '), {
          on_stdout = function(_, d, _)
            cargo_metadata = table.concat(d, '\n')
          end,
          on_stderr = function(_, d, _)
            cargo_metadata_err = table.concat(d, '\n')
          end,
          stdout_buffered = true,
          stderr_buffered = true,
        })
        if cm > 0 then
          cm = vim.fn.jobwait({ cm })[1]
        else
          cm = -1
        end
        local cargo_workspace_dir = nil
        if cm == 0 then
          cargo_workspace_dir = vim.fn.json_decode(cargo_metadata)['workspace_root']
        else
          vim.notify(
          string.format('[lspconfig] cmd (%q) failed:\n%s', table.concat(cmd, ' '), cargo_metadata_err),
          vim.log.levels.WARN
          )
        end
        return cargo_workspace_dir
        or cargo_crate_dir
        or lsp_util.root_pattern 'rust-project.json'(fname)
        or lsp_util.find_git_ancestor(fname)
      end
    }
  )
)

nvim_lsp.sumneko_lua.setup(coq.lsp_ensure_capabilities {
  on_attach = on_attach,
  cmd = containers.command('sumneko_lua'),
})

-- vue.js
nvim_lsp.vuels.setup(coq.lsp_ensure_capabilities {
  on_attach = on_attach,
  before_init = function(params)
    params.processId = vim.NIL
  end,
  cmd = containers.command('vuels'),
  --root_dir = lsp_util.root_pattern(".git", vim.fn.getcwd()),
})

-- ruby
-- nvim_lsp.solargraph.setup(coq.lsp_ensure_capabilities {
--   on_attach = on_attach,
--   -- cmd = containers.command('solargraph'),
--   cmd = containers.command('solargraph', {
--     image = "",
--     cmd = function (runtime, volume, image)
--       return {
--         runtime,
--         "container",
--         "run",
--         "--interactive",
--         "--rm",
--         "--volume",
--         volume,
--         image
--       }
--     end,
--   }),
--   root_dir = function(fname)

--     res = lsp_util.root_pattern "Gemfile" (fname)
--     or lsp_util.find_git_ancestor(fname)
--     or lsp_util.root_pattern "Gemfile" (fname .. "/src")
--     or lsp_util.find_git_ancestor(fname .. "/src")

--     print("solargraph for {} root dir: {}", fname, res)

--     return res
--   end
-- })


-- vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
--   vim.lsp.diagnostic.on_publish_diagnostics, {
--     virtual_text = true,
--     signs = true,
--     update_in_insert = false,
--     underline = true,
--     severity_sort = false,
--   }
-- )

-- nvim_lsp.phpactor.setup(coq.lsp_ensure_capabilities {
--   on_attach = on_attach,
--   cmd = containers.command('phpactor', {
--     image = "",
--     cmd = function (runtime, volume, image)
--       return {
--         runtime,
--         "container",
--         "run",
--         "--interactive",
--         "--rm",
--         "--volume",
--         volume,
--         image
--       }
--     end,
--   }),
-- })
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
------- packer -------
vim.cmd [[packadd packer.nvim]]
vim.cmd [[packloadall]]

return require('packer').startup(
  function ()
    use 'wbthomason/packer.nvim'

    use 'folke/tokyonight.nvim'
    use {'ms-jpq/coq_nvim', branch='coq'}
    -- apparently required for NERDTree or smth
    -- use 'nvim-treesitter/nvim-treesitter'
    use 'tpope/vim-commentary'
    use 'tpope/vim-obsession'
    use 'ThePrimeagen/git-worktree.nvim'
    use {
      'nvim-lualine/lualine.nvim',
      -- requires = {'kyazdani42/nvim-web-devicons', opt=true}
    }
    use {
      'nvim-telescope/telescope.nvim',
      requires = { {'nvim-lua/plenary.nvim'} }
    }

    use 'preservim/nerdtree'
    -- use 'Tabular'
    use 'mattn/emmet-vim'
    use 'jeetsukumaran/vim-buffergator'
    use 'qpkorr/vim-bufkill'
    use 'vimwiki/vimwiki'
    use 'ryanoasis/vim-devicons'
    use 'neovim/nvim-lspconfig'
    use 'lspcontainers/lspcontainers.nvim'

    use 'mhinz/vim-signify'
    use 'kdheepak/lazygit.nvim'

    use 'lervag/vimtex'
  end
)

