local vim = vim

local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)

local nvim_lsp = require'lspconfig'
local containers = require'lspcontainers'
local lsp_util = require'lspconfig.util'
local coq      = require'coq'

local on_attach = function(client)
  vim.api.nvim_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', {})
  vim.api.nvim_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', {})
  vim.api.nvim_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', {})

  -- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  vim.api.nvim_set_keymap('n', 'KK',  '<cmd>lua vim.lsp.buf.hover()<CR>', {})
  vim.api.nvim_set_keymap('', '<C-space>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', {})
  vim.api.nvim_set_keymap('n', 'KA', '<cmd>lua vim.lsp.buf.code_action()<CR>', {})
  -- vim.api.nvim_set_keymap('i', '<C-c>', '<cmd>lua vim.lsp.buf.completion()<CR>', {})
  vim.api.nvim_set_keymap('n', 'KR', '<cmd>lua vim.lsp.buf.rename()<CR>', {})
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

  vim.notify("[LSP_IMAGE DEBUG] root_dir cmd (before change): " .. table.concat(cmd, ' '))

  table.move(docker_cmd, 1, #docker_cmd, #cmd, cmd)

  vim.notify("[LSP_IMAGE DEBUG] root_dir cmd: " .. table.concat(cmd, ' '))

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

  vim.notify(
    "[LSP_IMAGE DEBUG] root_dir for " .. fname .. " is " .. result
  )

  return result
end

-- nvim_lsp.rust_analyzer.setup(
--   coq.lsp_ensure_capabilities({
--       on_attach = on_attach,
--       cmd = containers.command(
--         "rust_analyzer",
--         local_lsp.ensure_image_exists(
--           "rust_analyzer",
--           {
--             network = "bridge",
--           }
--         )
--       ),
--       settings = {
--         ["rust_analyzer"] = {
--           imports = {
--             granularity = {
--               groups = "module"
--             },
--             prefix = "self",
--           },
--           cargo = {
--             buildScripts = {
--               enable = true
--             }
--           },
--           procMacro = {
--             enable = true
--           }
--         }
--       },

--       -- get root_dir from container because there's no cargo in host
--       root_dir = get_root_dir_for_rust
--     }
--   )
-- )

nvim_lsp.sumneko_lua.setup(coq.lsp_ensure_capabilities {
  on_attach = on_attach,
  cmd = containers.command('sumneko_lua'),
})

-- vue.js
--nvim_lsp.vuels.setup(coq.lsp_ensure_capabilities {
--  on_attach = on_attach,
--  before_init = function(params)
--    params.processId = vim.NIL
--  end,
--  cmd = containers.command('vuels'),
--  --root_dir = lsp_util.root_pattern(".git", vim.fn.getcwd()),
--})

local function generate_root_dir_fn(lang)
  return function (fname)
    local_lsp.get_root_dir(lang, fname)
  end
end


nvim_lsp.volar.setup(coq.lsp_ensure_capabilities {
  on_attach = on_attach,
  root_dir = generate_root_dir_fn("volar"),
  cmd = containers.command(
    "volar",
    local_lsp.ensure_image_exists("volar")
  ),
})

-- php
nvim_lsp.phpactor.setup(coq.lsp_ensure_capabilities {
  on_attach = on_attach,
  cmd = containers.command(
    "phpactor",
    local_lsp.ensure_image_exists("phpactor")
  ),
  root_dir = generate_root_dir_fn("phpactor"),
})

-- packer/start/nvim-lspconfig/lua/lspconfig/configs.lua

-- ruby
-- nvim_lsp.solargraph.setup(coq.lsp_ensure_capabilities {
--   on_attach = on_attach,
--   -- cmd = ontainers.command('solargraph'),
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

