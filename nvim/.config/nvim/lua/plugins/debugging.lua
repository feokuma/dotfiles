-- Plugin nvim-dap para suporte ao Debug
return {
  {
    "mfussenegger/nvim-dap",

    dependencies = {
      "rcarriga/nvim-dap-ui",
    },

    config = function()
      local dap = require("dap")

      dap.adapters.coreclr = {
        type = "executable",
        command = "/home/feokuma/.local/share/nvim/mason/packages/netcoredbg/netcoredbg",
        args = { "--interpreter=vscode" },
      }

      dap.configurations.cs = {
        {
          type = "coreclr",
          request = "launch",
          name = "Launch .NET Core",
          program = function()
            local cwd = vim.fn.getcwd()
            local project_files = vim.fn.glob(cwd .. "/*.csproj", false, true)
            if #project_files == 0 then
              error("No .csproj file found in the workspace.")
            end
            local project_name = vim.fn.fnamemodify(project_files[1], ":t:r")

            local dll_path = vim.fn.glob(cwd .. "/bin/Debug/**/" .. project_name .. ".dll")
            if dll_path == "" then
              return vim.fn.input("Path to DLL > ", cwd .. "/", "file")
            end

            return dll_path
          end,
          cwd = "${workspaceFolder}",
          stopAtEntry = false,
        },
      }

      dap.adapters.node2 = {
        type = "executable",
        command = "node",
        args = { os.getenv("HOME") .. "/.vscode-node-debug2/out/src/nodeDebug.js" },
      }

      dap.configurations.javascript = {
        {
          name = "javascript-dap",
          type = "node2",
          request = "launch",
          program = "${file}",
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
          protocol = "inspector",
          console = "integratedTerminal",
        },
      }

      dap.configurations.typescript = {
        {
          name = "typescript-dap",
          type = "node2",
          request = "launch",
          program = "${file}",
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
          protocol = "inspector",
          console = "integratedTerminal",
          outFiles = { "${workspaceFolder}/dist/**/*.js" },
        },
      }
    end,
  },
}
