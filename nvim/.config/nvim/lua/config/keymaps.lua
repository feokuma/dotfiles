-- Keymaps do usuário. Carregado depois de `lazyvim.config.keymaps`.
-- Veja https://www.lazyvim.org/keymaps

local map = vim.keymap.set

-- Quickshell: roda o shell atual num terminal (equivale a `qs -p <dir>`).
-- Usa o diretório do arquivo atual como config path, então funciona tanto
-- para `~/.config/quickshell/shell.qml` quanto para configs por path.
map("n", "<leader>qs", function()
  local dir = vim.fn.expand("%:p:h")
  -- Se estiver num arquivo QML, sobe até achar shell.qml ou usa o dir atual.
  local root = vim.fs.root(dir, { "shell.qml", ".qmlls.ini", ".git" }) or dir
  Snacks.terminal.open("qs -p " .. vim.fn.shellescape(root))
end, { desc = "Quickshell: run config (qs -p)" })

-- Quickshell: checa sintaxe QML do arquivo atual com qmllint.
map("n", "<leader>qc", function()
  local file = vim.fn.expand("%:p")
  local qmllint = vim.fn.exepath("qmllint") ~= "" and "qmllint"
    or vim.fn.exepath("/usr/lib/qt6/bin/qmllint") ~= "" and "/usr/lib/qt6/bin/qmllint"
    or nil
  if not qmllint then
    vim.notify("qmllint não encontrado (qt6-declarative)", vim.log.levels.WARN)
    return
  end
  Snacks.terminal.open(qmllint .. " " .. vim.fn.shellescape(file))
end, { desc = "Quickshell: qmllint (check QML)" })
