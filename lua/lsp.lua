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
  vim.notify(
    string.format("generating root dir for %s and buffer %s which is %s", lang, fname, root_dir),
    vim.log.levels.WARN
  )
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

vim.lsp.config("rust_analyzer", {
  on_attach = on_attach,
  filetypes = {"rust"},
  cmd = generate_cmd_fn("rust_analyzer"),
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
  root_dir = generate_root_dir_fn("rust_analyzer"),
  before_init = function(params, config)
    if config.settings and config.settings['rust-analyzer'] then
      params.initializationOptions = config.settings['rust-analyzer']
    end
    params.processId = vim.NIL
  end,
})
vim.lsp.enable("rust_analyzer")


vim.lsp.config("ts_ls", {
  on_attach = on_attach,
  cmd = generate_cmd_fn("ts_ls"),
  root_dir = generate_root_dir_fn("ts_ls"),
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
vim.lsp.enable("ts_ls")


vim.lsp.config('vue_ls', {
  on_attach = on_attach,
  cmd = generate_cmd_fn("vue_ls"),
  root_dir = generate_root_dir_fn("vue_ls"),
})
vim.lsp.enable('vue_ls')

vim.lsp.config('svelte', {
  on_attach = on_attach,
  cmd = generate_cmd_fn("svelte"),
  root_dir = generate_root_dir_fn("svelte"),
  filetypes = {"svelte"}
})
vim.lsp.enable('svelte')


-----------
--- php ---
vim.lsp.config('phpactor', {
  on_attach = on_attach,
  cmd = generate_cmd_fn("phpactor"),
  root_dir = generate_root_dir_fn("phpactor"),
  filetypes = {"php"}
})
vim.lsp.enable('phpactor')


-- ruby
vim.lsp.config('solargraph', {
  on_attach = on_attach,
  cmd = generate_cmd_fn("solargraph"),
  root_dir = generate_root_dir_fn("solargraph"),
  filetypes = {"ruby"}
})
vim.lsp.enable('solargraph')

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
})


