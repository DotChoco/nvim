-- Replace empty lines in the rendering
vim.opt.fillchars = { eob = " " }

-- Variables
local opt = vim.opt
local api = vim.api

-- Config
require("config.lazy")

-- Mappings
require("mappings.genmap")
require("mappings.lspmap")
require("mappings.treemap")
require("mappings.telemap")

-- Erease the search history
opt.shada = ""

-- Indentation config
opt.expandtab = true
opt.smartindent = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.clipboard = "unnamedplus"

api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  pattern = "*",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- Own Implementations
require("ownp")



