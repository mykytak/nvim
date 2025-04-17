
return {
  root_file = "package.json",
  image = "lsp/volar",
  -- image = "lsp/volar-nix",
  -- cmd = {
  --   "/app/bin/vls",
  --   "--stdio"
  -- },
  init_options = {
    typescript = {
      tsdk = "/usr/local/lib/node_modules/typescript/lib"
    }
  },
  cmd = {
    "vue-language-server",
    "--stdio"
  },
  filetypes = {'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'json'},
}

