vim.keymap.set("n", "<C-n>", function()
  require("nvim-tree.api").tree.toggle()
end, { desc = "Toggle nvim-tree" })

vim.keymap.set("n", "<Space>e", function()
  require("nvim-tree.api").tree.open()
end, { desc = "Open nvim-tree" })
