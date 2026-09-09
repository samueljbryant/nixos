require("nvchad.configs.lspconfig").defaults()

local servers = { "basedpyright", "cssls", "ruff", "lua_ls", "ty", "clangd", "rust_analyzer", "bashls", "gopls",
  "texlab", "cmake-language-server", "ts_ls", "eslint", "ctags_ls", "sc_lsp", "nil_ls", "zls",
}
local lspconfig = vim.lsp.config
local luarocks_lib = {}
local seen_lua_paths = {}

-- get the luarocks path dynamically
local luarocks_path_list = vim.fn.system("luarocks path --lr-path")
for i in string.gmatch(luarocks_path_list, "([^;]+)") do
  local path = string.match(i, "([^?]+)")
  if seen_lua_paths[path] == nil then
    table.insert(luarocks_lib, path)
    seen_lua_paths[path] = true
  end
end



-- lspconfig("ctags_ls", {
--   cmd = { "ctags-lsp", "--tagfile", vim.fn.expand("~/.cache/nvim/scnvim/tags") },
--   filetypes = { "supercollider", "scd", "sc" },
-- })

local caps = vim.lsp.protocol.make_client_capabilities()
caps.workspace.didChangeWatchedFiles.dynamicRegistration = true

-- Resolve sc_lsp from PATH so the in-development binary comes from the project's
-- direnv/flake dev shell (see templates/supercollider). Only attach where a
-- SuperCollider.toml marks the root, i.e. dirs bootstrapped with `initsc`.
lspconfig("sc_lsp", {
  cmd = { "sc_lsp" },
  capabilities = caps,
  filetypes = { "supercollider", "scd", "sc" },
  root_markers = { "SuperCollider.toml" },
})

lspconfig("lua_ls", {
  settings = {
    Lua = {
      runtime = "LuaJIT",
      diagnostics = {
        globals = { "love" },
      },
      workspace = { library = luarocks_lib }
    }
  }
})

lspconfig("ruff", {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
})

lspconfig("ty", {
  cmd = { "ty", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
})

lspconfig("clangd", {
  -- cmd = { "clangd", "--extra-arg=-std=c32" },
})

lspconfig("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      check = {
        command = "clippy",
      },
    },
  },
})

lspconfig("bashls", {
  settings = {
    cmd = { "bash-language-server", "start" },
    filetypes = { "bash", "sh" }
  }
})

lspconfig("hls", {
  settings = {
    haskell = {
      formattingProvider = "ormolu",
    },
  },
})



lspconfig("eslint", {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "eslint.config.js", "eslint.config.mjs", ".eslintrc.js", ".eslintrc.json", ".eslintrc", "package.json" },
  settings = {
    validate = "on",
    format = false,
  },
})

vim.lsp.enable(servers)
vim.lsp.enable(servers)
