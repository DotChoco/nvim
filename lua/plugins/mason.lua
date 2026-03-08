return {
  {
    "mason-org/mason.nvim",
    version = "~1.0.0",
    cmd = "Mason",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    version = "~1.0.0",
    lazy = true,
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {},
  },
}
