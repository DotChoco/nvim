return {
  'nvim-lualine/lualine.nvim',
  event = "VeryLazy",
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local conf = require("config.lualine.conf")
    require("lualine").setup(conf.get_config())
  end,
}
