-- Opções do usuário. Carregado depois de `lazyvim.config.options`.
-- Veja `:h option` e `https://www.lazyvim.org/configuration/general`.

local opt = vim.opt

-- Usa 2 espaços por padrão; QML usa `qmlformat` para formatação real.
opt.shiftwidth = 2
opt.tabstop = 2

-- Relativenumber já vem do LazyVim; garante spell desligado em QML.
-- (QML tem muitas palavras-chave que poluiriam o spell.)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "qml", "qmljs" },
  callback = function()
    vim.opt_local.spell = false
  end,
})
