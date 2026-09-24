require "nvchad.autocmds"

vim.opt.relativenumber = true

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function(args)
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4

    -- auto-continue multiline macros: append a trailing '\' when <CR> is
    -- pressed on a "#define" line or a line continuing one (prev line ends in '\')
    vim.keymap.set("i", "<CR>", function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local line = vim.api.nvim_get_current_line()
      local prev = row > 1 and vim.api.nvim_buf_get_lines(0, row - 2, row - 1, false)[1] or ""

      local starts_macro = line:match("^%s*#define") ~= nil
      local continues_macro = prev:match("\\%s*$") ~= nil

      if (starts_macro or continues_macro) and not line:match("\\%s*$") then
        return " \\<CR>"
      end

      return "<CR>"
    end, { buffer = args.buf, expr = true })
  end
})
