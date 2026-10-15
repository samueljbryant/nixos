return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "leoluz/nvim-dap-go",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end,         desc = "Dap Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end,                  desc = "Dap Continue" },
      { "<leader>di", function() require("dap").step_into() end,                 desc = "Dap Step Into" },
      { "<leader>do", function() require("dap").step_over() end,                 desc = "Dap Step Over" },
      { "<leader>dO", function() require("dap").step_out() end,                  desc = "Dap Step Out" },
      { "<leader>dr", function() require("dap").repl.toggle() end,               desc = "Dap REPL" },
      { "<leader>dl", function() require("dap").run_last() end,                  desc = "Dap Run Last" },
      { "<leader>dt", function() require("dap").terminate() end,                 desc = "Dap Terminate" },
      { "<leader>du", function() require("dapui").toggle() end,                  desc = "Dap UI Toggle" },
      { "<leader>dgt", function() require("dap-go").debug_test() end,            desc = "Dap Go Debug Test", ft = "go" },
      { "<leader>dgl", function() require("dap-go").debug_last_test() end,       desc = "Dap Go Debug Last Test", ft = "go" },
    },
    config = function()
      local dap, dapui = require "dap", require "dapui"

      dapui.setup()
      require("nvim-dap-virtual-text").setup()
      require("dap-go").setup {
        delve = {
          path = "dlv", -- resolved from $PATH, provided by nix dev shells (see templates/go/flake.nix)
        },
      }

      -- Prefer the project's uv-managed .venv (has debugpy as a dev dep);
      -- fall back to whatever python3 is on $PATH (e.g. a nix dev shell).
      local venv_python = vim.fn.getcwd() .. "/.venv/bin/python"
      local python_path = vim.fn.executable(venv_python) == 1 and venv_python or "python3"
      require("dap-python").setup(python_path)

      -- Odin has no dedicated dap plugin; wire lldb-dap directly.
      -- Resolved from $PATH, provided by nix dev shells (see templates/odin/flake.nix).
      dap.adapters["lldb-dap"] = {
        type = "executable",
        command = "lldb-dap",
        name = "lldb-dap",
      }
      dap.configurations.odin = {
        {
          type = "lldb-dap",
          request = "launch",
          name = "Debug (odin build -debug)",
          cwd = "${workspaceFolder}",
          program = function()
            local out = vim.fn.getcwd() .. "/.dap-debug-bin"
            local result = vim.fn.system { "odin", "build", "./src", "-debug", "-out:" .. out }
            if vim.v.shell_error ~= 0 then
              error("odin build failed:\n" .. result)
            end
            return out
          end,
          args = {},
          stopOnEntry = false,
        },
      }

      -- Zig has no dedicated dap plugin either; reuse the same lldb-dap adapter.
      -- Resolved from $PATH, provided by nix dev shells (see templates/zig/flake.nix).
      dap.configurations.zig = {
        {
          type = "lldb-dap",
          request = "launch",
          name = "Debug (zig build-exe src/main.zig)",
          cwd = "${workspaceFolder}",
          program = function()
            local out = vim.fn.getcwd() .. "/.dap-debug-bin"
            local result = vim.fn.system { "zig", "build-exe", "src/main.zig", "-O", "Debug", "-femit-bin=" .. out }
            if vim.v.shell_error ~= 0 then
              error("zig build-exe failed:\n" .. result)
            end
            return out
          end,
          args = {},
          stopOnEntry = false,
        },
      }

      -- C/C++ have no dedicated dap plugin and no single canonical build command
      -- (make/cmake/plain cc vary by project), so prompt for the compiled binary
      -- instead of building it here. Reuses the lldb-dap adapter above.
      -- Resolved from $PATH, provided by nix dev shells (see templates/c/flake.nix).
      local cpp_config = {
        {
          type = "lldb-dap",
          request = "launch",
          name = "Launch",
          cwd = "${workspaceFolder}",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          args = {},
          stopOnEntry = false,
        },
      }
      dap.configurations.c = cpp_config
      dap.configurations.cpp = cpp_config

      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn" })
    end,
  },
}
