
return {
  root_file = "package.json",
  image = "lsp/volar",
  cmd = {
    "vue-language-server",
    "--stdio"
  },
  init_options = {
    typescript = {
      tsdk = "/usr/local/lib/node_modules/typescript/lib"
    }
  },
  filetypes = {'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'json'},
}

