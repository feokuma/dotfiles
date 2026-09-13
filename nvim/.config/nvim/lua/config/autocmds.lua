-- Autocmds do usuário. Carregado depois de `lazyvim.config.autocmds`.
-- Veja https://www.lazyvim.org/configuration/general#auto-commands

-- Garante que *.qml e *.qmljs usem o filetype `qml` (e `qmljs` onde fizer
-- sentido). Neovim >= 0.10 já detecta `qml`, mas reforçamos para
-- instalações mínimas e para o LSP qmlls.
vim.filetype.add({
  extension = {
    qml = "qml",
    qmljs = "qmljs",
  },
})

-- Ao salvar shell.qml, o Quickshell regenera o `.qmlls.ini` sozinho na
-- próxima execução (`qs`). Não precisamos gerar nada aqui.
