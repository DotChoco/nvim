---@diagnostic disable: undefined-global
local function tb(fn)
  return function()
    require("telescope.builtin")[fn]()
  end
end

-- Keymaps para modo normal
vim.keymap.set('n', '<leader>ff', tb("find_files"), { desc = 'Buscar archivos' })
vim.keymap.set('n', '<leader>fg', tb("live_grep"), { desc = 'Buscar texto (grep)' })
vim.keymap.set('n', '<leader>fb', tb("buffers"), { desc = 'Listar buffers' })
vim.keymap.set('n', '<leader>fh', tb("oldfiles"), { desc = 'Archivos recientes' })

-- Git
vim.keymap.set('n', '<leader>gc', tb("git_commits"), { desc = 'Commits de git' })
vim.keymap.set('n', '<leader>gs', tb("git_status"), { desc = 'Estado de git' })

-- LSP
vim.keymap.set('n', '<leader>td', tb("lsp_definitions"), { desc = 'Ir a definición' })
vim.keymap.set('n', '<leader>tr', tb("lsp_references"), { desc = 'Referencias' })
vim.keymap.set('n', '<leader>ts', tb("lsp_document_symbols"), { desc = 'Símbolos del documento' })

-- Otros útiles
vim.keymap.set('n', '<leader>km', tb("keymaps"), { desc = 'Mostrar keymaps' })
vim.keymap.set('n', '<leader>ht', tb("help_tags"), { desc = 'Ayuda' })
vim.keymap.set('n', '<leader>ma', tb("marks"), { desc = 'Marcadores' })

