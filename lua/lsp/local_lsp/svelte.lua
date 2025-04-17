return {
  root_file = "package.json",
  image = "lsp/svelte",
  cmd = {
    "svelteserver",
    "--stdio"
  },
  init_options = {
    typescript = {
      tsdk = "/usr/local/lib/node_modules/typescript/lib"
    }
  },
  filetypes = {'svelte'},
}

