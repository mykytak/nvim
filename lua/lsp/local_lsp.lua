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


local function get_local_config(fname)
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

  return cfg
end

LocalLsp.get_local_config = get_local_config;



local function get_project_image(lang, fname)

  -- return lang related image, not static one
  local default_image = "lsp/rust"

  if skip_local_images then
    return default_image
  end


  local local_config = get_local_config(fname)

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
  cfg.cmd_builder = function(runtime, workdir, image, network, docker_volume)

    -- I can extract this whole thing into separate func
    -- If it's rust specific - I can use it as is.
    -- If it's not - I probably can generalize it.

    local local_config = get_local_config(workdir)

    vim.notify("[LSP_IMAGE DEBUG] local root_dir found: " .. (local_config.root_dir or "NONE"))

    local cargo_name = ""
    if local_config.root_dir ~= nil then
      cargo_name = local_config.root_dir .. "/"
    end
    cargo_name = cargo_name .. "Cargo.toml"

    local cargo_crate_dir = lsp_util.root_pattern(cargo_name)(workdir)

    if local_config.root_dir ~= nil then
      cargo_crate_dir = cargo_crate_dir .. "/" .. local_config.root_dir
    end

    if cargo_crate_dir ~= nil then
      vim.notify("[LSP_IMAGE DEBUG] cargo_crate_dir: " .. cargo_crate_dir)
    else
      vim.notify("[LSP_IMAGE DEBUG] no cargo_crate_dir found for: " .. cargo_name .. " in " .. fname)
    end


    -- if local_config.root_dir ~= nil then
    --   fname = fname .. "/" .. local_config.root_dir
    -- end

    -- local cargo_crate_dir = lsp_util.root_pattern "Cargo.toml"(fname)

    -- if cargo_crate_dir ~= nil then
    --   vim.notify("[LSP_IMAGE DEBUG] cargo_crate_dir: " .. cargo_crate_dir)
    -- else
    --   vim.notify("[LSP_IMAGE DEBUG] no cargo_crate_dir found in " .. fname)
    -- end


    local mnt_volume
    if docker_volume ~= nil then
      mnt_volume ="--volume="..docker_volume..":"..workdir..":z"
    elseif cargo_crate_dir ~= nil then
      mnt_volume = "--volume="..cargo_crate_dir..":"..workdir..":z"
    else
      mnt_volume = "--volume="..workdir..":"..workdir..":z"
    end

    vim.notify("[LSP_IMAGE DEBUG] mnt_volume: "..mnt_volume)

    local def_config = require("lspconfig.server_configurations.rust_analyzer").default_config;

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

