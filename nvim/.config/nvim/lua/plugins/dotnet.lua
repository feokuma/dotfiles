-- Suporte a desenvolvimento .NET/C# (LazyVim).
--
-- Base: extras oficiais do LazyVim habilitados via `lazyvim.json`
-- (o equivalente ao `:LazyExtras`; declarar extras aqui em `plugins/`
-- quebraria a ordem de imports do LazyVim):
--   - `dap.core`: nvim-dap + dap-ui + virtual text + keybindings <leader>d*
--   - `lang.dotnet`: extra oficial (treesitter c_sharp, netcoredbg, csharpier,
--       neotest-vstest). O LSP usado é o Roslyn (roslyn_ls), configurado
--       abaixo; o OmniSharp do extra fica desativado.
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

  --- Localiza o .csproj do projeto do buffer atual.
  local function projeto_atual()
    return vim.fs.find(function(name)
      return name:match("%.csproj$") ~= nil
    end, { upward = true, path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)) })[1]
  end

  --- Resolve a dll do projeto do buffer atual:
  --- <proj>/bin/Debug/<tfm>/<AssemblyName>.dll
  local function dll_do_projeto()
    local project = projeto_atual()
    if not project then
      return nil
    end
    -- Usa o diretório do projeto de forma absoluta (via `:p`) e absolutiza
    -- o resultado do glob. O `dotnet build`/netcoredbg roda com cwd do
    -- diretório do projeto, então o caminho absoluto evita depender de onde
    -- o nvim foi aberto (ex.: raiz da solução).
    local base = vim.fn.fnamemodify(project, ":p:h")
    local dll = vim.fn.glob(base .. "/bin/Debug/**/" .. vim.fn.fnamemodify(project, ":t:r") .. ".dll")
    if dll ~= "" then
      return vim.fn.fnamemodify(dll, ":p")
    end
    return dll
  end

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
        local dll = dll_do_projeto()
        if dll == "" or dll == nil then
          vim.notify("Dll não encontrada — rode `dotnet build` antes de debugar.", vim.log.levels.ERROR)
          return nil
        end
        return dll
      end,
      -- Roda o debugger no diretório do projeto do buffer atual, não onde o
      -- nvim foi aberto. `${workspaceFolder}` (= getcwd) aponta para a raiz
      -- da solução ao abrir o nvim lá e o netcoredbg falhava ao resolver o
      -- caminho da dll, terminando a sessão na hora (DAP UI abria e fechava).
      cwd = function()
        local project = projeto_atual()
        return project and vim.fs.dirname(project) or vim.fn.getcwd()
      end,
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

  -- <leader>dd: compila o projeto do buffer atual (se necessário) e lança
  -- o Debugger direto, sem picker nem pedir dll a mao. E o atalho de
  -- "uma tecla para debugar" da palestra.
  vim.keymap.set("n", "<leader>dd", function()
    local dap = require("dap")
    local config = vim.tbl_filter(function(c)
      return c.name == "Launch dll (build current project)"
    end, dap.configurations.cs or {})[1]
    if not config then
      vim.notify("Config 'Launch dll (build current project)' não registrada.", vim.log.levels.ERROR)
      return
    end

    local dll = dll_do_projeto()
    if dll ~= "" and dll ~= nil then
      dap.run(config)
      return
    end

    local project = projeto_atual()
    if not project then
      vim.notify("Nenhum .csproj encontrado acima do buffer atual.", vim.log.levels.ERROR)
      return
    end

    vim.notify("Compilando " .. vim.fn.fnamemodify(project, ":t") .. " ...", vim.log.levels.INFO)
    local resultado = vim.system({ "dotnet", "build", project }):wait()
    if resultado.code ~= 0 then
      vim.notify("dotnet build falhou — ver :messages", vim.log.levels.ERROR)
      return
    end
    vim.notify("Build concluído. Debugando...", vim.log.levels.INFO)
    dap.run(config)
  end, { desc = "Debug: build + launch (projeto atual)" })
end

return {
  -- LSP C#: Roslyn (servidor oficial da Microsoft). Muda do OmniSharp,
  -- que esta fim-de-vida, com crash de inlay hints e sem suporte a
  -- .slnx/.NET 10. O lspconfig `roslyn_ls` ja detecta .sln e .slnx.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Desativa o OmniSharp do extra lang.dotnet
        omnisharp = { enabled = false },
        -- Roslyn LSP: instalado/gerenciado pelo mason-lspconfig
        roslyn_ls = {},
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
      local tools = { "netcoredbg", "csharpier", "roslyn-language-server" }
      for _, tool in ipairs(tools) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end
    end,
  },

  -- Debug de testes: o neotest-vstest precisa saber que DAP deve usar
  -- (netcoredbg). `<leader>td` (Debug Nearest, do extra test.core) lanca
  -- o testhost do projetio de teste sob o netcoredbg — e ai sim os
  -- breakpoints em arquivos de teste param.
  {
    "Nsidorenco/neotest-vstest",
    init = function()
      ---@type neotest_vstest.Config
      vim.g.neotest_vstest = {
        dap_settings = {
          type = "netcoredbg",
        },
      }
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
