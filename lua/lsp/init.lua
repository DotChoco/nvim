local M = {}

local initialized = false

local servers = {
  csharp_ls = { module = "lsp.csharp" },
  clangd = { module = "lsp.clangd" },
  cssls = { module = "lsp.css" },
  lua_ls = { module = "lsp.lua_lsp" },
  gdscript = { module = "lsp.gdscript" },
  html = { module = "lsp.html" },
  svelte = { module = "lsp.svlt" },
  ts_ls = { module = "lsp.ts" },
}

local managed_server_names = {}
local servers_by_ft = {}
local enabled_servers = {}
local prune_timer = nil

local function has_open_buffer_for_filetypes(filetypes)
  if not filetypes or #filetypes == 0 then
    return false
  end

  local wanted = {}
  for _, ft in ipairs(filetypes) do
    wanted[ft] = true
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" then
      local ft = vim.bo[bufnr].filetype
      if wanted[ft] then
        return true
      end
    end
  end

  return false
end

local function client_has_open_buffers(client)
  local attached = client.attached_buffers or {}
  for bufnr, _ in pairs(attached) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" then
      return true
    end
  end
  return false
end

local function stop_unused_clients()
  for _, client in ipairs(vim.lsp.get_clients()) do
    local is_managed = managed_server_names[client.name] or client.name == "rust-analyzer" or client.name == "rust_analyzer"
    local is_stopped = client.is_stopped and client:is_stopped() or false
    if is_managed and not is_stopped then
      local filetypes = client.config and client.config.filetypes or {}
      local has_open_buffers = (#filetypes > 0 and has_open_buffer_for_filetypes(filetypes)) or client_has_open_buffers(client)
      if not has_open_buffers then
        client:stop(true)
      end
    end
  end
end

local function schedule_prune()
  vim.defer_fn(stop_unused_clients, 100)
end

local function ensure_enabled_for_filetype(ft)
  local target_servers = servers_by_ft[ft]
  if not target_servers then
    return
  end

  for _, server_name in ipairs(target_servers) do
    if not enabled_servers[server_name] then
      vim.lsp.enable(server_name)
      enabled_servers[server_name] = true
    end
  end
end

function M.setup()
  if initialized then
    return
  end
  initialized = true

  vim.diagnostic.config({
    underline = true,
    virtual_text = false,
    severity_sort = true,
    signs = false,
  })

  for server_name, server in pairs(servers) do
    local ok, config = pcall(require, server.module)
    if ok and type(config) == "table" then
      vim.lsp.config(server_name, config)
      managed_server_names[server_name] = true

      for _, ft in ipairs(config.filetypes or {}) do
        servers_by_ft[ft] = servers_by_ft[ft] or {}
        table.insert(servers_by_ft[ft], server_name)
      end
    else
      vim.notify(
        ("LSP config not loaded for %s (%s): %s"):format(server_name, server.module, tostring(config)),
        vim.log.levels.WARN
      )
    end
  end

  local group = vim.api.nvim_create_augroup("OwnpLspManager", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
      ensure_enabled_for_filetype(vim.bo[args.buf].filetype)
    end,
  })

  vim.api.nvim_create_autocmd({
    "BufDelete",
    "BufUnload",
    "BufWipeout",
    "BufHidden",
    "WinClosed",
    "TabClosed",
    "VimResized",
  }, {
    group = group,
    callback = schedule_prune,
  })

  if not prune_timer then
    prune_timer = vim.uv.new_timer()
    prune_timer:start(120000, 120000, vim.schedule_wrap(stop_unused_clients))
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if prune_timer then
        prune_timer:stop()
        prune_timer:close()
        prune_timer = nil
      end
    end,
  })

  vim.api.nvim_create_user_command("LspPruneUnused", stop_unused_clients, {
    desc = "Stop LSP clients without active buffers for their filetypes",
  })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      ensure_enabled_for_filetype(vim.bo[bufnr].filetype)
    end
  end
end

return M
