return {
	'nvim-tree/nvim-tree.lua',
	cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus", "NvimTreeFindFile" },
	keys = {
		{
			"<C-n>",
			function()
				require("nvim-tree.api").tree.toggle()
			end,
			desc = "Toggle nvim-tree",
		},
		{
			"<Space>e",
			function()
				require("nvim-tree.api").tree.open()
			end,
			desc = "Open nvim-tree",
		},
	},
	dependencies = {
		'nvim-tree/nvim-web-devicons',
	},
	opts = {
		actions = {
			open_file = {
				window_picker = {
					enable = false
				},
			}
		},
    filesystem_watchers = {
      enable = true,
      ignore_dirs = {
        "target",
      },
    },
		view = {
			side = "right",
			centralize_selection = true,
			adaptive_size = false,
			width = 25,
			preserve_window_proportions = true,
			float = {
				enable = true,
				quit_on_focus_loss = false,
				open_win_config = function()
					local screen_w = vim.opt.columns:get()
					local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
					local window_w = screen_w * 0.6
					local window_h = screen_h * 0.7
					local window_w_int = math.floor(window_w)
					local window_h_int = math.floor(window_h)
					local center_x = (screen_w - window_w) / 2
					local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
					return {
						border = "rounded",
						relative = "editor",
						row = center_y,
						col = center_x,
						width = window_w_int,
						height = window_h_int,
						style = "minimal",
					}
				end,
			},
		},
		renderer = {
			full_name = false,
			root_folder_label = ":t",
			decorators = { "Git", "Open", "Hidden", "Modified", "Bookmark", "Diagnostics", "Copied", "Cut", },
			special_files = { "Cargo.toml", "Makefile", "README.md", "readme.md" },
		},
		filters = {
			dotfiles = true,
			git_ignored = false,
			custom = {
				".meta",
				"obj",
			}
		},
	},
	config = function(_, opts)
		vim.g.loaded = 1
		vim.g.loaded_netrwPlugin = 1
		require("nvim-tree").setup(opts)

		-- Highlights específicos para ventana flotante
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "NvimTree",
			callback = function()
				vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
				vim.api.nvim_set_hl(0, "FloatBorder", { bg = "", fg = "NONE" })
				vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { bg = "NONE", fg = "NONE" })
			end,
		})
	end
}
