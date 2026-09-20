return {
  {
    "stevearc/conform.nvim",
    event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    'davidgranstrom/scnvim',
    ft = 'supercollider',
    config = function()
      local scnvim = require 'scnvim'
      local map = scnvim.map
      local map_expr = scnvim.map_expr
      scnvim.setup {
        keymaps = {
          ['<M-e>'] = map('editor.send_line', { 'i', 'n' }),
          ['<C-e>'] = {
            map('editor.send_block', { 'i', 'n' }),
            map('editor.send_selection', 'x'),
          },
          ['<CR>'] = map('postwin.toggle'),
          ['<M-CR>'] = map('postwin.toggle', 'i'),
          ['<M-L>'] = map('postwin.clear', { 'n', 'i' }),
          ['<C-k>'] = map('signature.show', { 'n', 'i' }),
          ['<F12>'] = map('sclang.hard_stop', { 'n', 'x', 'i' }),
          ['<leader>st'] = map('sclang.start'),
          ['<leader>sk'] = map('sclang.recompile'),
          ['<F1>'] = map_expr('s.boot'),
          ['<F2>'] = map_expr('s.meter'),
        },
        editor = {
          highlight = {
            color = 'IncSearch',
          },
        },
        postwin = {
          float = {
            enabled = false,
          },
        },
      }
    end
  },
  { "hrsh7th/nvim-cmp",                   enabled = true },
  -- {
  --   "quangnguyen30192/cmp-nvim-tags",
  --   ft = "supercollider",
  --   config = function()
  --     require("cmp").setup.filetype("supercollider", {
  --       sources = require("cmp").config.sources({
  --         { name = "tags",   option = { exact_match = false, file_names = { vim.fn.expand("~/.cache/nvim/scnvim/tags") } } },
  --         { name = "buffer" },
  --       })
  --     })
  --   end,
  -- },
  { 'davidgranstrom/telescope-scdoc.nvim' },
  { 'kylechui/nvim-surround',             event = "VeryLazy" },
  {
    "GustavEikaas/easy-dotnet.nvim",
    -- Neovim maps .sln -> "solution" and .csproj/.fsproj -> "xml", not their own
    -- filetypes, so those need pattern-based `event` triggers instead of `ft`.
    ft = { "cs", "fsharp" },
    event = {
      "BufReadPre *.sln",
      "BufReadPre *.csproj",
      "BufReadPre *.fsproj",
      "BufNewFile *.sln",
      "BufNewFile *.csproj",
      "BufNewFile *.fsproj",
    },
    dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap", },
    config = function()
      require("easy-dotnet").setup()
    end
  },
  -- {
  --   'saghen/blink.cmp',
  --   dependencies = { 'rafamadriz/friendly-snippets' },
  --   version = '1.*',
  --   opts = {
  --     keymap = { preset = 'default' },
  --     appearance = { nerd_font_variant = 'mono' },
  --     sources = {
  --       default = { 'lsp', 'path', 'snippets', 'buffer' },
  --     },
  --     fuzzy = { implementation = "prefer_rust_with_warning" }
  --   },
  -- },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim", "lua", "vimdoc",
        "html", "css", "c3",
      },
    },
  },
}
