return {
  root_file = "composer.json",
  image = "lsp/phpactor",
  -- image = "lsp/phpactor-nix",
  cmd = {
    -- "/app/bin/phpactor",
    "/usr/local/bin/phpactor",
    "language-server"
  },
  -- init_options = {
  --   ["language_server_phpstan.enabled"] = true,
  --   ["language_server_phpstan.bin"] = "/app/bin/phpstan",
  --   ["language_server_psalm.enabled"] = true,
  --   ["language_server_psalm.bin"] = "/app/bin/psalm",
  -- }
}
