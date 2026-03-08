---@diagnostic disable: undefined-global
return {
  'mrcjkb/rustaceanvim',
  version = '^5',
  ft = { "rust" },
  init = function()
    -- NOTE: rustaceanvim's default `server.auto_attach` checks for "absolute" file paths.
    -- On some Windows builds (e.g. MSYS2/MinGW, where `vim.uv.os_uname().sysname` is like
    -- `MINGW32_NT-10.0`) rustaceanvim may treat the OS as non-Windows, making `C:\...`
    -- paths fail that check and preventing the LSP from starting.
    local function auto_attach(bufnr)
      return vim.bo[bufnr].buftype == ""
        and vim.api.nvim_buf_get_name(bufnr) ~= ""
        and vim.fn.executable("rust-analyzer") == 1
    end

    vim.g.rustaceanvim = {
      server = {
        auto_attach = auto_attach,
        settings = {
          ["rust-analyzer"] = {
            inlayHints = {
              bindingModeHints = { enable = true },
              chainingHints = { enable = true },
              -- closingBraceHints = { enable = true },
              closureReturnTypeHints = { enable = "always" },
              -- lifetimeElisionHints = { enable = "always", useParameterNames = true },
              maxLength = 25,
              parameterHints = { enable = true },
              -- reborrowHints = { enable = "always" },
              typeHints = { enable = true },
            },
            cargo = {
              allFeatures = false,
            },
            check = {
              allTargets = false,
            },
            cachePriming = {
              enable = false,
            },
            lru = {
              capacity = 1024,
            },
            files = {
              excludeDirs = {
                ".git",
                "target",
                "node_modules",
              },
            },
          },
        },
      },
    }

    -- habilitar inlay hints automáticamente
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
        end
      end,
    })
  end,
}
