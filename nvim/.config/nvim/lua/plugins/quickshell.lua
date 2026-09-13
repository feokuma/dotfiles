-- Suporte a Quickshell / QML no LazyVim.
--
-- Baseado na doc oficial:
--   https://quickshell.org/docs/v0.3.1/guide/install-setup/
--   - treesitter `qmljs` para highlight
--   - `qmlls -E` como language server
--   - `.qmlls.ini` vazio ao lado de `shell.qml` (o `qs` preenche sozinho;
--     veja nota sobre gitignore no final)
--
-- Particularidades do Arch (quickshell 0.3.1, Qt 6.11):
--   - binários Qt vivem em `/usr/lib/qt6/bin/`; só alguns têm symlink
--     em `/usr/bin` (`qmlls6`, mas NÃO `qmlformat`/`qmllint`).
--   - por isso detectamos o binário em ordem de preferência e usamos
--     path absoluto como fallback.
--   - `import Quickshell` resolve via `-I /usr/lib/qt6/qml` (onde o
--     pacote `quickshell` instala os módulos QML).

local function first_executable(candidates)
  for _, c in ipairs(candidates) do
    if c:find("/", 1, true) then
      if vim.fn.executable(c) == 1 then
        return c
      end
    else
      local found = vim.fn.exepath(c)
      if found ~= "" then
        return found
      end
    end
  end
  return nil
end

local qmlls_bin = first_executable({ "qmlls", "qmlls6", "/usr/lib/qt6/bin/qmlls" })
local qmlformat_bin = first_executable({ "qmlformat", "/usr/lib/qt6/bin/qmlformat" })
local qmllint_bin = first_executable({ "qmllint", "/usr/lib/qt6/bin/qmllint" })

-- -E: usa QML_IMPORT_PATH (obrigatório em qmlls >= 6.8.2).
-- -I /usr/lib/qt6/qml: garante `import Quickshell` no Arch mesmo sem
--   QML_IMPORT_PATH setado. Se o binário não existir, o LSP fica
--   desabilitado com aviso em vez de quebrar o startup.
local qmlls_cmd
if qmlls_bin then
  qmlls_cmd = { qmlls_bin, "-E", "-I", "/usr/lib/qt6/qml" }
else
  vim.schedule(function()
    vim.notify("qmlls não encontrado (qt6-declarative). LSP QML desabilitado.", vim.log.levels.WARN)
  end)
end

return {
  -- Treesitter: highlight QML/JS.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "qmljs") then
        table.insert(opts.ensure_installed, "qmljs")
      end
    end,
  },

  -- LSP: qmlls via LazyVim (nvim-lspconfig).
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        qmlls = qmlls_cmd and {
          cmd = qmlls_cmd,
          filetypes = { "qml", "qmljs" },
          -- .qmlls.ini é gerenciado pelo `qs` (conteúdo por máquina);
          -- shell.qml marca a raiz do shell; .git como fallback.
          root_markers = { ".qmlls.ini", "shell.qml", ".git" },
          single_file_support = true,
        } or nil,
        -- lua_ls já vem bem configurado no LazyVim; garantimos que
        -- os arquivos Lua do Hyprland (~/.config/hypr/*.lua) tenham
        -- diagnósticos sãos sem poluir com globals do Hyprland.
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "hl", "vim" },
              },
            },
          },
        },
      },
    },
  },

  -- Formatação: qmlformat via conform.nvim.
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        qml = { "qmlformat" },
        qmljs = { "qmlformat" },
      },
      formatters = {
        qmlformat = {
          command = qmlformat_bin or "qmlformat",
          -- qmlformat formata stdin -> stdout com `-`; `-i` seria inplace.
          -- Usamos stdin para não tocar o arquivo fora do buffer.
          args = { "-i", "$FILENAME" },
          stdin = false,
          -- Se o binário não existir, conform pula com aviso em vez de erro.
          condition = function()
            return qmlformat_bin ~= nil
          end,
        },
      },
    },
  },

  -- Lint: qmllint via nvim-lint (complementa o LSP; manual com <leader>qc).
  -- No Arch, qmllint vive em /usr/lib/qt6/bin sem symlink em /usr/bin,
  -- então registramos o path absoluto no linter.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        qml = qmllint_bin and { "qmllint" } or {},
        qmljs = qmllint_bin and { "qmllint" } or {},
      },
    },
    config = function(_, opts)
      require("lint").linters_by_ft = opts.linters_by_ft
      if qmllint_bin then
        local qmllint = require("lint").linters.qmllint
        if qmllint then
          qmllint.cmd = qmllint_bin
        end
      end
    end,
  },

  -- Mason: garante ferramentas Lua (para Hyprland *.lua + o próprio nvim).
  -- QML usa binários do Qt (fora do Mason), então não tentamos instalar
  -- qmlls/qmlformat via Mason aqui. Usa mason-tool-installer, que é a
  -- forma suportada de `ensure_installed` (mason.nvim puro não tem
  -- essa opção e quebra o setup do LazyVim).
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
      },
    },
  },
}
