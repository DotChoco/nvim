return {
  "neovim/nvim-lspconfig",
  ft = {
    "c",
    "cpp",
    "objc",
    "objcpp",
    "cuda",
    "css",
    "cs",
    "html",
    "javascript",
    "javascriptreact",
    "lua",
    "gd",
    "gdscript",
    "gdscript3",
    "rust",
    "svelte",
    "typescript",
    "typescriptreact",
  },
  dependencies = {
    "saghen/blink.cmp",
  },
  config = function()
    require("lsp").setup()
  end,
}
