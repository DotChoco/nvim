local M = require("lsp.utils")

local capabilities, on_attach = M.get_common()
local bin_ext = M.get_bin_ext()
local bin_path = M.get_bin_path()

---@type vim.lsp.Config
return {
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = { bin_path .. "lua-language-server" .. bin_ext },
  filetypes = { "lua" },
  root_markers = {
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git",
  },
  single_file_support = true,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          vim.fn.stdpath("config") .. "/lua",
        },
      },
      telemetry = { enable = false },
    },
  },
}
