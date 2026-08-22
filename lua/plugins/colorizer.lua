return {
  "catgoose/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  init = function()
    vim.opt.termguicolors = true
  end,
  opts = {
    filetypes = { "*" },
    user_commands = true,
    options = {
      parsers = {
        css = true,
        tailwind = { enable = true },
      },
      display = {
        mode = "background",
      },
    },
  },
}
