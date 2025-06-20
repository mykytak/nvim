local vim = vim

local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)

local nvim_lsp   = require'lspconfig'
local containers = require'lspcontainers'
local lsp_util   = require'lspconfig.util'

local set_lsp_buf_keymap = function(key, command)
  vim.keymap.set('n', key, '<cmd>lua vim.lsp.buf.'..command..'<CR>', {})
end

vim.opt.completeopt = { "menuone", "noselect", "popup" }
local on_attach = function(client, bufnr)
  vim.lsp.completion.enable(true, client.id, bufnr, {
    autotrigger = true,
    convert = function (item)
      return { abbr = item.label:gsub('%b()', '') }
    end,
  })
  set_lsp_buf_keymap('gd', 'definition()')
  set_lsp_buf_keymap('gr', 'references()')
  set_lsp_buf_keymap('gi', 'implementation()')

  -- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  set_lsp_buf_keymap('KK',  'hover()')
  set_lsp_buf_keymap('<C-s>', 'signature_help()')
  set_lsp_buf_keymap('KA', 'code_action()')
  vim.keymap.set('i', '<C-space>', vim.lsp.completion.get, { desc = 'trigger autocompletion' })
  set_lsp_buf_keymap('KR', 'rename()')

  -- require "lsp_signature".on_attach({
  --   bind = true,
  --   handler_opts = {
  --     border = "rounded"
  --   }
  -- }, bufnr)
end

-- vim.lsp.set_log_level("debug")

local local_lsp = require("lsp.local_lsp")

local function get_root_dir_for_rust(fname)
  local cmd = containers.command(
    "rust_analyzer",
    local_lsp.ensure_image_exists(
      "rust_analyzer",
      { network = "bridge" }
    )
  )

  local docker_cmd = { 'cargo', 'metadata', '--no-deps', '--format-version', '1' }

  table.move(docker_cmd, 1, #docker_cmd, #cmd, cmd)

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
  local result = cargo_workspace_dir
  or lsp_util.root_pattern 'rust-project.json'(fname)
  or lsp_util.find_git_ancestor(fname)

  return result
end

nvim_lsp.rust_analyzer.setup({
  on_attach = on_attach,
  cmd = containers.command(
    "rust_analyzer",
    local_lsp.ensure_image_exists(
      "rust_analyzer",
      { network = "bridge" }
    )
  ),
  settings = {
    ["rust_analyzer"] = {
      imports = {
        granularity = { groups = "module" },
        prefix = "self",
      },
      cargo = {
        buildScripts = { enable = true }
      },
      procMacro = { enable = true }
    }
  },

  root_dir = get_root_dir_for_rust
})

nvim_lsp.lua_ls.setup({
  on_attach = on_attach,
  cmd = containers.command('lua_ls'),
})

local function generate_root_dir_fn(lang)
  return function(fname)
    return local_lsp.get_root_dir(lang, fname)
  end
end


nvim_lsp.volar.setup({
  on_attach = on_attach,
  cmd = containers.command(
    "volar",
    local_lsp.ensure_image_exists("volar")
  ),
  init_options = {
    typescript = {
      tsdk = "/usr/local/lib/node_modules/typescript/lib"
    }
  },
  root_dir = generate_root_dir_fn("volar"),
  filetypes = {'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'json'},
})

nvim_lsp.svelte.setup({
  on_attach = on_attach,
  cmd = containers.command(
    "svelte",
    local_lsp.ensure_image_exists("svelte")
  ),
  root_dir = generate_root_dir_fn("svelte"),
})

-- nvim_lsp.tsserver.setup {
--   before_init = function(params)
--     params.processId = vim.NIL
--   end,
--   cmd = containers.command("tsserver")
-- }

-----------
--- php ---
nvim_lsp.phpactor.setup({
  on_attach = on_attach,
  cmd = containers.command(
    "phpactor",
    local_lsp.ensure_image_exists("phpactor")
  ),
  root_dir = generate_root_dir_fn("phpactor"),
})


-- ruby
nvim_lsp.solargraph.setup({
  on_attach = on_attach,
  -- cmd = ontainers.command('solargraph'),
  cmd = containers.command(
    "solargraph",
    local_lsp.ensure_image_exists("solargraph")
  ),
  root_dir = generate_root_dir_fn("solargraph")
})

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
})


