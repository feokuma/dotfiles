-- Suporte a desenvolvimento .NET/C# (LazyVim).
--
-- Base: extras oficiais do LazyVim habilitados via `lazyvim.json`
-- (o equivalente ao `:LazyExtras`; declarar extras aqui em `plugins/`
-- quebraria a ordem de imports do LazyVim):
--   - `dap.core`: nvim-dap + dap-ui + virtual text + keybindings <leader>d*
--   - `lang.dotnet`: omnisharp (LSP, Roslyn analyzers, organize imports),
--       omnisharp-extended-lsp (gd via .sln), netcoredbg, csharpier,
--       treesitter c_sharp, neotest-vstest
--   - `test.core`: neotest + keybindings <leader>t*
--
-- Este arquivo segue o padrão de `go.lua`: adiciona apenas o que os
-- extras não cobrem.

-- ------------------------------------------------------------------
-- DAP: configurações .NET práticas
-- ------------------------------------------------------------------
-- O extra lang.dotnet registra o adapter netcoredbg e uma config básica
-- "Launch file" (pede o path da dll à mão). Aqui adicionamos configs que
-- resolvem a dll do projeto do buffer atual e attach a processo.
local function setup_dap()
  local dap = require("dap")

  if not dap.adapters["netcoredbg"] then
    dap.adapters["netcoredbg"] = {
      type = "executable",
      command = vim.fn.exepath("netcoredbg"),
      args = { "--interpreter=vscode" },
      options = { detached = false },
    }
  end

  local configs = dap.configurations.cs or {}

  local function has(name)
    for _, c in ipairs(configs) do
      if c.name == name then
        return true
      end
    end
    return false
  end

  if not has("Launch dll (build current project)") then
    table.insert(configs, {
      type = "netcoredbg",
      name = "Launch dll (build current project)",
      request = "launch",
      program = function()
        -- Localiza a dll do projeto acima do buffer atual:
        -- <proj>/bin/Debug/<tfm>/<AssemblyName>.dll
        local project = vim.fs.find(function(name)
          return name:match("%.csproj$") ~= nil
        end, { upward = true, path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)) })[1]
        if not project then
          vim.notify("Nenhum .csproj encontrado acima do buffer atual.", vim.log.levels.ERROR)
          return nil
        end
        local dll = vim.fn.glob(vim.fs.dirname(project) .. "/bin/Debug/**/" .. vim.fn.fnamemodify(project, ":t:r") .. ".dll")
        if dll == "" then
          vim.notify("Dll não encontrada — rode `dotnet build` antes de debugar.", vim.log.levels.ERROR)
          return nil
        end
        return dll
      end,
      cwd = "${workspaceFolder}",
      stopAtEntry = false,
    })
  end

  if not has("Attach to process") then
    table.insert(configs, {
      type = "netcoredbg",
      name = "Attach to process",
      request = "attach",
      processId = require("dap.utils").pick_process,
    })
  end

  dap.configurations.cs = configs
end

return {
  -- LSP: ajustes omnisharp (o extra já configura analyzers, organize
  -- imports e gd via .sln com omnisharp-extended-lsp).
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = {
          -- Roslyn analyzers já habilitados pelo extra; reforçamos
          -- análise em tempo de edição e suporte a load de projetos.
          enable_editorconfig_support = true,
          enable_ms_build_load_projects_on_demand = false,
          analyze_open_documents_only = true,
        },
      },
    },
  },

  -- Lint: analyzers Roslyn já rodam via omnisharp LSP (diagnósticos
  -- nativos do compilador/analyzers). Nenhum linter externo necessário;
  -- nvim-lint não tem linter C# útil sem duplicar o que o LSP já dá.
  -- Formatação: csharpier já registrado pelo extra via conform.
  --
  -- Mason: garante netcoredbg/csharpier via mason-tool-installer
  -- (padrão de go.lua). Ambos já são garantidos pelo extra lang.dotnet;
  -- aqui é redundância defensiva no mesmo estilo do resto do repositório.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local tools = { "netcoredbg", "csharpier" }
      for _, tool in ipairs(tools) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end
    end,
  },

  -- DAP: registra configs C# extras. O extra lang.dotnet registra o
  -- adapter/configs via `opts` (side effect), e o config do dap.core do
  -- LazyVim não deve ser sobrescrito (ele sobe dap-ui, sinais etc.).
  -- Usamos o mesmo gancho `opts` para encadear nossas configurações.
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      setup_dap()
    end,
  },
}
