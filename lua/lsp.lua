local vim = vim

local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)

local containers = require'lspcontainers'

local set_lsp_buf_keymap = function(key, command)
  vim.keymap.set('n', key, vim.lsp.buf[command], {buffer=true})
end

vim.opt.completeopt = { "menuone", "noselect", "popup" }
local on_attach = function(client, bufnr)
  vim.lsp.completion.enable(true, client.id, bufnr, {
    autotrigger = true,
    convert = function (item)
      return { abbr = item.label:gsub('%b()', '') }
    end,
  })
  set_lsp_buf_keymap('gd', 'definition')
  set_lsp_buf_keymap('gr', 'references')
  set_lsp_buf_keymap('gi', 'implementation')

  -- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  set_lsp_buf_keymap('KK',  'hover')
  set_lsp_buf_keymap('<C-s>', 'signature_help')
  set_lsp_buf_keymap('KA', 'code_action')
  vim.keymap.set('i', '<C-space>', vim.lsp.completion.get, { desc = 'trigger autocompletion' })
  set_lsp_buf_keymap('KR', 'rename')

  -- require "lsp_signature".on_attach({
  --   bind = true,
  --   handler_opts = {
  --     border = "rounded"
  --   }
  -- }, bufnr)
end

local local_lsp = require("local_lsp")


vim.lsp.config('lua_ls', {
  on_attach = on_attach,
  cmd = containers.command('lua_ls'),
  filetypes = {"lua"},
})
vim.lsp.enable('lua_ls')

local function generate_root_dir_fn(lang)
  return function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root_dir = local_lsp.get_root_dir(lang, fname)
    on_dir(root_dir)
  end
end

local function generate_cmd_fn(lsp)
  return function(dispatchers, config)
    local my_cfg = local_lsp.ensure_image_exists(
            lsp,
            { network = "bridge" }
          )

    if my_cfg.sub_cmd ~= nil then
      my_cfg.cmd = my_cfg.sub_cmd
    end

    local cmd = containers.command(
      lsp,
      my_cfg
    )

    return vim.lsp.rpc.start(cmd, dispatchers, {
      cwd = config.cmd_cwd,
      env = config.cmd_env,
      detached = config.detached,
    })
  end
end

local setup_lsp = function(name, cfg, disable)
  local final_cfg = {
    on_attach = on_attach,
    cmd = generate_cmd_fn(name),
    root_dir = generate_root_dir_fn(name),
  }

  if type(cfg) == "table" then
    for k, v in pairs(cfg) do
      final_cfg[k] = v;
    end
  end

  vim.lsp.config(name, final_cfg);

  if disable then return end

  vim.lsp.enable(name)
end

setup_lsp("rust_analyzer", {
  settings = {
    ["rust_analyzer"] = {
      imports = {
        granularity = { groups = "module" },
        prefix = "self",
      },
      cargo = {
        buildScripts = { enable = false }
      },
      procMacro = { enable = false },
    }
  },

  capabilities = {
    experimental = {
      serverStatusNotification = true,
    },
  },
  before_init = function(params, config)
    if config.settings and config.settings['rust-analyzer'] then
      params.initializationOptions = config.settings['rust-analyzer']
    end
    params.processId = vim.NIL
  end,
})


setup_lsp( "ts_ls", {
  init_options = {
    plugins = {
      {
        name = "@vue/typescript-plugin",
        location = "/usr/local/lib/node_modules/@vue/language-server",
        languages = { "vue" },
        configNamespace = "typescript",
      }
    }
  },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
    'json',
    'vue',
  },
})

setup_lsp("vue_ls")
setup_lsp("svelte")
setup_lsp("phpactor")
setup_lsp("solargraph")

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
})


