local M = require("lsp.utils")

local capabilities, on_attach = M.get_common()
local bin_ext = M.get_bin_ext()
local bin_path = M.get_bin_path()

local mason_clangd = bin_path .. "clangd" .. bin_ext
local llvm_clangd = "C:\\Program Files\\LLVM\\bin\\clangd.exe"

local function join_path(a, b)
  if a:sub(-1) == "/" or a:sub(-1) == "\\" then
    return a .. b
  end
  return a .. "/" .. b
end

local function has_file(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function is_build_dir_name(name)
  return name:match("^build") ~= nil
    or name:match("^cmake%-build") ~= nil
    or name == "out"
    or name == ".build"
end

local function find_compile_commands_in_child_build_dirs(root)
  local scan = vim.uv.fs_scandir(root)
  if not scan then
    return nil
  end

  while true do
    local name, kind = vim.uv.fs_scandir_next(scan)
    if not name then
      break
    end

    if kind == "directory" and is_build_dir_name(name) then
      local abs = join_path(root, name)
      if has_file(join_path(abs, "compile_commands.json")) then
        return abs
      end

      local nested_scan = vim.uv.fs_scandir(abs)
      if nested_scan then
        while true do
          local nested_name, nested_kind = vim.uv.fs_scandir_next(nested_scan)
          if not nested_name then
            break
          end
          if nested_kind == "directory" then
            local nested_abs = join_path(abs, nested_name)
            if has_file(join_path(nested_abs, "compile_commands.json")) then
              return nested_abs
            end
          end
        end
      end
    end
  end

  return nil
end

local function find_compile_commands_dir(root)
  if not root or root == "" then
    return nil
  end

  if has_file(join_path(root, "compile_commands.json")) then
    return root
  end

  local candidates = {
    "build",
    "build/debug",
    "build/release",
    "cmake-build-debug",
    "cmake-build-release",
    "out/build",
  }

  for _, dir in ipairs(candidates) do
    local abs = join_path(root, dir)
    if has_file(join_path(abs, "compile_commands.json")) then
      return abs
    end
  end

  return find_compile_commands_in_child_build_dirs(root)
end

local function find_project_root(fname)
  return vim.fs.root(fname, {
    ".clangd",
    ".clang-tidy",
    ".clang-format",
    "compile_commands.json",
    "compile_flags.txt",
    "configure.ac",
    "CMakeLists.txt",
    "meson.build",
    "build.ninja",
    ".git",
  })
end

local function find_root_and_compile_dir(fname)
  local root = find_project_root(fname)
  if not root then
    return nil, nil
  end
  return root, find_compile_commands_dir(root)
end

local function get_first_real_buffer_path()
  local current = vim.api.nvim_get_current_buf()
  local current_name = vim.api.nvim_buf_get_name(current)
  if current_name ~= "" then
    return current_name
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "" then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" then
        return name
      end
    end
  end

  return nil
end

local function resolve_clangd_cmd()
  if vim.uv.fs_stat(mason_clangd) then
    return mason_clangd
  end
  if vim.fn.executable("clangd") == 1 then
    return "clangd"
  end
  if vim.uv.fs_stat(llvm_clangd) then
    return llvm_clangd
  end
  return "clangd"
end

local function switch_source_header(bufnr, client)
  local method_name = "textDocument/switchSourceHeader"
  if not client or not client:supports_method(method_name) then
    vim.notify(("method %s is not supported by clangd in this buffer"):format(method_name))
    return
  end

  local params = vim.lsp.util.make_text_document_params(bufnr)
  client:request(method_name, params, function(err, result)
    if err then
      vim.notify(tostring(err), vim.log.levels.ERROR)
      return
    end
    if not result then
      vim.notify("corresponding file cannot be determined")
      return
    end
    vim.cmd.edit(vim.uri_to_fname(result))
  end, bufnr)
end

local function symbol_info(bufnr, client)
  local method_name = "textDocument/symbolInfo"
  if not client or not client:supports_method(method_name) then
    vim.notify("Clangd client not found", vim.log.levels.ERROR)
    return
  end

  local win = vim.api.nvim_get_current_win()
  local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
  client:request(method_name, params, function(err, res)
    if err or not res or #res == 0 then
      return
    end

    local container = ("container: %s"):format(res[1].containerName)
    local name = ("name: %s"):format(res[1].name)
    vim.lsp.util.open_floating_preview({ name, container }, "", {
      height = 2,
      width = math.max(string.len(name), string.len(container)),
      focusable = false,
      focus = false,
      title = "Symbol Info",
    })
  end, bufnr)
end

local function show_clangd_info(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local root = fname ~= "" and find_project_root(fname) or nil
  local compile_dir = root and find_compile_commands_dir(root) or nil

  vim.notify(
    ("clangd root: %s\ncompile_commands_dir: %s"):format(root or "nil", compile_dir or "nil"),
    vim.log.levels.INFO
  )
end

---@class ClangdInitializeResult: lsp.InitializeResult
---@field offsetEncoding? string

---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    local root = config.root_dir
    local fname = get_first_real_buffer_path()
    local compile_dir = find_compile_commands_dir(root)
    if fname and (not compile_dir) then
      local _, detected_compile_dir = find_root_and_compile_dir(fname)
      compile_dir = detected_compile_dir or compile_dir
    end
    local args = {
      resolve_clangd_cmd(),
      "--background-index=false",
      "--header-insertion=never",
      "--clang-tidy=false",
      "--pch-storage=disk",
      "--query-driver=C:/msys64/**/gcc*.exe,C:/msys64/**/g++*.exe,C:/msys64/**/clang*.exe,C:/mingw64/**/gcc*.exe,C:/mingw64/**/g++*.exe",
    }

    if compile_dir then
      table.insert(args, "--compile-commands-dir=" .. compile_dir)
    end

    return vim.lsp.rpc.start(args, dispatchers, {
      cwd = root,
      env = config.cmd_env,
      detached = config.detached,
    })
  end,
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname == "" then
      return
    end

    local root = find_project_root(fname)

    if root then
      on_dir(root)
    end
  end,
  workspace_required = true,
  single_file_support = false,
  capabilities = vim.tbl_deep_extend("force", capabilities or {}, {
    textDocument = {
      completion = {
        editsNearCursor = true,
      },
    },
    offsetEncoding = { "utf-8", "utf-16" },
  }),
  ---@param init_result ClangdInitializeResult
  on_init = function(client, init_result)
    if init_result and init_result.offsetEncoding then
      client.offset_encoding = init_result.offsetEncoding
    end
  end,
  on_attach = function(client, bufnr)
    if on_attach then
      on_attach(client, bufnr)
    end

    vim.api.nvim_buf_create_user_command(bufnr, "LspClangdSwitchSourceHeader", function()
      switch_source_header(bufnr, client)
    end, { desc = "Switch between source/header" })

    vim.api.nvim_buf_create_user_command(bufnr, "LspClangdShowSymbolInfo", function()
      symbol_info(bufnr, client)
    end, { desc = "Show symbol info" })

    vim.api.nvim_buf_create_user_command(bufnr, "LspClangdInfo", function()
      show_clangd_info(bufnr)
    end, { desc = "Show clangd root and compile_commands dir" })
  end,
}
