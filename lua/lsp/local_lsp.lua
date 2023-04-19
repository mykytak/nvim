local vim = vim

local LocalLsp = {}

local skip_local_images = false
local config_name = ".lspconfig"

local lsp_util = require'lspconfig.util'


-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
local function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    local formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      return formatting .. tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      return formatting .. tostring(v)
    else
      return formatting .. v
    end
  end
end


local function get_local_config(fname, lang)
  local root_dir = lsp_util.root_pattern(config_name)(fname)

  local cfg = {}

  -- no local config found
  if root_dir == nil then
    vim.notify("[LSP_IMAGE DEBUG] no local config found for " .. fname)
    return cfg
  end

  local f, err = loadfile(root_dir .. "/" .. config_name, "t", cfg)

  if f then
    f()
  else
    vim.notify("[LSP_IMAGE DEBUG] error loading local config for " .. fname .. ": " .. err)
  end

  return cfg[lang] or {}
end

LocalLsp.get_local_config = get_local_config;


local function get_root_dir(lang, fname)
  local cfg = get_local_config(fname, lang)

  vim.notify("[LSP_IMAGE DEBUG] local root_dir found: " .. (cfg.root_dir or "NONE"))

  local lang_config = require("lsp.local_lsp." .. lang)

  local root_name = ""
  if cfg.root_dir ~= nil then
    root_name = cfg.root_dir .. "/"
  end
  if lang_config ~= nil and lang_config.root_file ~= nil then
    root_name = root_name .. lang_config.root_file
  end
  -- root_name = root_name .. "Cargo.toml"

  local root_dir = lsp_util.root_pattern(root_name)(fname)

  if cfg.root_dir ~= nil then
    root_dir = root_dir .. "/" .. cfg.root_dir
  end

  return root_dir
end

LocalLsp.get_root_dir = get_root_dir

local function get_project_image(lang, fname)

  local lang_config = require("lsp.local_lsp." .. lang)
  local supported_languages = require("lspcontainers.init").supported_languages

  local default_image =
    (lang_config ~= nil and lang_config.image ~= nil)
      and lang_config.image
      or  supported_languages[lang].image

  if skip_local_images then
    return default_image
  end


  local local_config = get_local_config(fname, lang)

  if local_config.image == nil then
    return default_image
  end

  vim.notify("[LSP_IMAGE DEBUG] local image loaded: " .. local_config.image)

  return local_config.image or default_image
end

LocalLsp.get_project_image = get_project_image;



function LocalLsp.ensure_image_exists(lang, cfg)
  if skip_local_images then
    return cfg
  end

  local fname = vim.api.nvim_buf_get_name(0)

  cfg.image = cfg.image or get_project_image(lang, fname)
  cfg.root_dir = cfg.root_dir or get_root_dir(lang, fname)
  cfg.cmd_builder = function(runtime, workdir, image, network, docker_volume)

    -- I can extract this whole thing into separate func
    -- If it's rust specific - I can use it as is.
    -- If it's not - I probably can generalize it.

    local local_config = get_local_config(workdir, lang)

    vim.notify("[LSP_IMAGE DEBUG] local root_dir found: " .. (local_config.root_dir or "NONE"))

    local root_dir = get_root_dir(lang, fname)

    local mnt_volume
    if docker_volume ~= nil then
      mnt_volume ="--volume="..docker_volume..":"..workdir..":z"
    elseif root_dir ~= nil then
      mnt_volume = "--volume="..root_dir..":"..workdir..":z"
    else
      mnt_volume = "--volume="..workdir..":"..workdir..":z"
    end

    vim.notify("[LSP_IMAGE DEBUG] mnt_volume: "..mnt_volume)

    local def_config = require("lspconfig.server_configurations." .. lang).default_config;

    vim.notify("[LSP_IMAGE DEBUG] configs loaded: " .. tprint(def_config))
    vim.notify("[LSP_IMAGE DEBUG] cfg.cmd: " .. (cfg.cmd or tprint(def_config.cmd)))

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
      cfg.cmd or table.concat(def_config.cmd)
    }
  end

  -- I should hijack into LspStart

  -- local fname = vim.api.nvim_buf_get_name(0)
  -- local local_config = get_local_config(fname)

  vim.notify("[LSP_IMAGE DEBUG] ensure_image_exist cfg: " .. tprint(cfg))
  return cfg

  -- wrapper around lsp containers (cmd)
  -- aimed to ensure lsp image exist for a specific project
  --
  -- some sort of project-related config
  -- with image tag being passed to containers.command
  -- with check if image exist
  -- and reminder to check for updates for it every now and then
end


return LocalLsp;

