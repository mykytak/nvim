local vim = vim

local LocalLsp = {}

local SKIP_LOCAL_IMAGES = false
local config_name = ".lspconfig"

local lsp_util = require'lspconfig.util'


-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
local function tprint (tbl, indent)
  if not type(tbl) == "table" then
    return tostring(tbl)
  end
  if tbl == nil then return "nil" end
  if not indent then indent = 0 end
  local res = ""
  for k, v in pairs(tbl) do
    local formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      res = res..formatting..tprint(v, indent+1).."\n"
    elseif type(v) == 'boolean' then
      res = res..formatting..tostring(v).."\n"
    elseif type(v) == 'function' then
      res = res..formatting.." (func)\n"
    else
      res = res..formatting..v.."\n"
    end
  end
  return res
end

LocalLsp.tprint = tprint


local function get_local_config(fname, lang)
  local root_dir = lsp_util.root_pattern(config_name)(fname)

  local cfg = {}

  -- no local config found
  if root_dir == nil then
    return {}
  end

  local f, err = loadfile(root_dir .. "/" .. config_name, "t", cfg)

  if f then
    f()
  else
  end

  return cfg[lang] or {}
end

LocalLsp.get_local_config = get_local_config;


local function get_root_dir(lang, fname)
  local cfg = get_local_config(fname, lang)

  local lang_config = require("lsp.local_lsp." .. lang)

  local root_name = ""
  if cfg.root_dir ~= nil then
    root_name = cfg.root_dir .. "/"
  end
  if lang_config ~= nil and lang_config.root_file ~= nil then
    root_name = root_name .. lang_config.root_file
  end

  local root_dir = lsp_util.root_pattern(root_name)(fname)

  if cfg.root_dir ~= nil then
    root_dir = root_dir .. "/" .. cfg.root_dir
  end

  -- this one and src should be merged together
  if root_dir == nil then
    root_dir = lsp_util.root_pattern("app/"..root_name)(fname)
    if root_dir ~= nil then
      root_dir=root_dir.."/app"
    end
  end

  if root_dir == nil then
    root_dir = lsp_util.root_pattern("src/"..root_name)(fname)
    if root_dir ~= nil then
      root_dir=root_dir.."/src"
    end
  end

  return root_dir
end

LocalLsp.get_root_dir = get_root_dir

local function get_project_cmd(lang, fname)
  local lang_config = require("lsp.local_lsp."..lang)
  local supported_languages = require("lspcontainers.init").supported_languages

  local default_cmd =
    (lang_config ~= nil and lang_config.cmd ~= nil)
      and lang_config.cmd
      or supported_languages[lang].cmd
      or ""

  if SKIP_LOCAL_IMAGES then return default_cmd end

  local local_config = get_local_config(fname, lang)

  if local_config.cmd == nil then
    return default_cmd
  end

  return local_config.cmd or default_cmd
end

local function get_project_image(lang, fname)

  local lang_config = require("lsp.local_lsp." .. lang)
  local supported_languages = require("lspcontainers.init").supported_languages

  local default_image =
    (lang_config ~= nil and lang_config.image ~= nil)
      and lang_config.image
      or  supported_languages[lang].image

  if SKIP_LOCAL_IMAGES then return default_image end

  local local_config = get_local_config(fname, lang)

  if local_config.image == nil then
    return default_image
  end

  return local_config.image or default_image
end

LocalLsp.get_project_image = get_project_image;


local function make_cmd_builder(lang, cfg)
  return function(runtime, workdir, image, network, docker_volume)

    local fname = cfg.fname

    local local_config = get_local_config(workdir, lang)

    local root_dir = get_root_dir(lang, fname)

    local mnt_volume
    if docker_volume ~= nil then
      mnt_volume ="--volume="..docker_volume..":"..workdir..":z"
    elseif root_dir ~= nil then
      mnt_volume = "--volume="..root_dir..":"..workdir..":z"
    else
      mnt_volume = "--volume="..workdir..":"..workdir..":z"
    end

    if type(cfg.cmd) ~= "table" then cfg.cmd = { cfg.cmd } end

    local result = {
      runtime,
      "container",
      "run",
      "--interactive",
      "--pid=host",
      "--rm",
      "--network="..network,
      "--workdir="..workdir,
      mnt_volume,
      image
    }

    for k, v in pairs(cfg.cmd) do
      table.insert(result, v)
    end

    return result
  end
end


function LocalLsp.ensure_image_exists(lang, cfg)
  if SKIP_LOCAL_IMAGES then return cfg end

  if cfg == nil then
    cfg = {}
  end

  cfg.fname = vim.api.nvim_buf_get_name(0)

  cfg.cmd = cfg.cmd or get_project_cmd(lang, cfg.fname)
  cfg.image = cfg.image or get_project_image(lang, cfg.fname)
  cfg.root_dir = cfg.root_dir or get_root_dir(lang, cfg.fname)
  cfg.cmd_builder = make_cmd_builder(lang, cfg)

  -- local fname = vim.api.nvim_buf_get_name(0)
  -- local local_config = get_local_config(fname)

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

