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
  config = function()
    local ok, compat = pcall(require, "rustaceanvim.compat")
    if not ok then
      return
    end

    local function get_attached_buffers(client_id)
      local client = vim.lsp.get_client_by_id(client_id)
      if not client or type(client.attached_buffers) ~= "table" then
        return {}
      end

      local bufs = {}
      for bufnr, attached in pairs(client.attached_buffers) do
        if attached and vim.api.nvim_buf_is_valid(bufnr) then
          table.insert(bufs, bufnr)
        end
      end
      return bufs
    end

    compat.client_request = function(client, method, params, handler, bufnr)
      return client:request(method, params, handler, bufnr)
    end

    compat.client_notify = function(client, method, params)
      return client:notify(method, params)
    end

    compat.client_is_stopped = function(client)
      return client:is_stopped()
    end

    local status_ok, server_status = pcall(require, "rustaceanvim.server_status")
    if status_ok and type(server_status.handler) == "function" then
      local original_handler = server_status.handler
      server_status.handler = function(err, result, ctx, cfg)
        local original_get_buffers = vim.lsp.get_buffers_by_client_id
        vim.lsp.get_buffers_by_client_id = get_attached_buffers
        local ok_handler, handler_err = pcall(original_handler, err, result, ctx, cfg)
        vim.lsp.get_buffers_by_client_id = original_get_buffers
        if not ok_handler then
          error(handler_err)
        end
      end
    end
  end,
}
