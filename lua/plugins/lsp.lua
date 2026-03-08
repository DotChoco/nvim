return {
  "neovim/nvim-lspconfig",
  ft = {
    "c",
    "cpp",
    "objc",
    "objcpp",
    "cuda",
    "cs",
    "lua",
    "gd",
    "gdscript",
    "gdscript3",
    "rust",
  },
  dependencies = {
    "saghen/blink.cmp",
  },
  config = function()
    require("lsp").setup()
  end,
}
