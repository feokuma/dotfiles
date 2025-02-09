return {
  "Exafunction/codeium.vim",
  event = "InsertEnter",
  config = function()
    vim.g.codeium_disable_bindings = 0
  end,
}
