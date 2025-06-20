return {
  root_file = "composer.json",
  -- image = "lsp/phpactor",
  image = "lsp/phpactor-nix",
  cmd = {
    -- "/usr/local/bin/phpactor",

    "/app/bin/phpactor", -- nix version
    "language-server",
    "-vvv",
    "--working-dir",
    "###working_dir###",
  },
  init_options = {
    ["language_server_phpstan.enabled"] = false,
    ["language_server_phpstan.bin"] = "/app/bin/phpstan",
    ["language_server_psalm.enabled"] = false,
    ["language_server_psalm.bin"] = "/app/bin/psalm",
  }
}
