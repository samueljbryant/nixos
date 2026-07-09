local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    python = { "ruff_format" },
    c = { "clang_format" },
    rust = { "rustfmt", lsp_format = "fallback" },
    go = { "goimports", "gofmt" },
    cs = { "csharpier" },
  },

  -- formatters = {
  --   ruff = {
  --     args = {"format", "--line-length", "88", "stdin-filename", "$FILENAME", "-"}
  --   }
  -- },

  -- lspconfig("ruff", {})

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
