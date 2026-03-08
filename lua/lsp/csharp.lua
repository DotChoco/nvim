local M = require("lsp.utils")
local util = require("lspconfig.util")

local capabilities, on_attach = M.get_common()
local handlers = {}
local ok, csharpls_extended = pcall(require, "csharpls_extended")

if ok then
  handlers["textDocument/definition"] = csharpls_extended.handler
  handlers["textDocument/typeDefinition"] = csharpls_extended.handler
end

---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    return vim.lsp.rpc.start({ "csharp-ls" }, dispatchers, {
      cwd = config.cmd_cwd or config.root_dir,
      env = config.cmd_env,
      detached = config.detached,
    })
  end,
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    on_dir(util.root_pattern '*.sln'(fname) or util.root_pattern '*.slnx'(fname) or util.root_pattern '*.csproj'(fname))
  end,
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "cs" },
  init_options = {
    AutomaticWorkspaceInit = true,
  },
  get_language_id = function(_, ft)
    if ft == "cs" then
      return "csharp"
    end
    return ft
  end,
  handlers = handlers,
}
