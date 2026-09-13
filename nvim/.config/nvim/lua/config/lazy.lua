-- Bootstrap lazy.nvim + LazyVim.
-- Baseado no starter oficial do LazyVim (https://github.com/LazyVim/starter).
-- Mantido minimalista: extras de linguagem vivem em `lua/plugins/`.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- Base LazyVim.
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- Plugins do usuário (inclui quickshell/QML).
    { import = "plugins" },
  },
  defaults = {
    -- Compila do HEAD em vez de release: acompanha Neovim 0.12.
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- checa updates automaticamente
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
