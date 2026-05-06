local M = {}

local parser_by_filetype = {
  css = "css",
  html = "html",
  javascript = "javascript",
  ["javascript.jsx"] = "javascript",
  javascriptreact = "javascript",
  rust = "rust",
  svelte = "svelte",
  typescript = "typescript",
  ["typescript.tsx"] = "tsx",
  typescriptreact = "tsx",
}

local function rust_parser_path()
  return vim.fn.stdpath("config") .. "/parser/rust.so"
end

local function ensure_rust_parser()
  local parser = rust_parser_path()
  if vim.uv.fs_stat(parser) then
    return vim.treesitter.language.add("rust", { path = parser })
  end

  return vim.treesitter.language.add("rust")
end

local function ensure_parser(parser_name)
  if parser_name == "rust" then
    return ensure_rust_parser()
  end

  return vim.treesitter.language.add(parser_name)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("OwnpTreeSitter", { clear = true })

  vim.treesitter.language.register("javascript", "javascriptreact")
  vim.treesitter.language.register("javascript", "javascript.jsx")
  vim.treesitter.language.register("tsx", "typescriptreact")
  vim.treesitter.language.register("tsx", "typescript.tsx")

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = vim.tbl_keys(parser_by_filetype),
    callback = function(args)
      local filetype = vim.bo[args.buf].filetype
      local parser = parser_by_filetype[filetype]
      if not parser then
        return
      end

      local ok, result = pcall(ensure_parser, parser)
      if not ok or result ~= true then
        vim.notify(
          ("Tree-sitter no disponible para %s: %s"):format(filetype, tostring(result)),
          vim.log.levels.WARN
        )
        return
      end

      vim.treesitter.start(args.buf, parser)
    end,
  })
end

return M
