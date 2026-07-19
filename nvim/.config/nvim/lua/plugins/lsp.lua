local servers = require("plugins.lsp.servers")
local ensure_installed = {}

for server, config in pairs(servers) do
  if config ~= false then
    table.insert(ensure_installed, server)
  end
end

return {
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    opts = {
      ensure_installed = ensure_installed,
      auto_install = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP: Hover" })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP: Rename" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: Code Action" })
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "LSP: Go to Definition" })
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, { desc = "LSP: Go to References" })
      vim.keymap.set("n", "<leader>gi", vim.lsp.buf.implementation, { desc = "LSP: Go to Implementation" })
      vim.keymap.set("n", "<leader>gl", vim.diagnostic.open_float, { desc = "LSP: Show Diagnostics" })
      vim.keymap.set("n", "<leader>gq", vim.diagnostic.setloclist, { desc = "LSP: Set Diagnostics to Location List" })
      vim.keymap.set("n", "<leader>gR", vim.lsp.buf.format, { desc = "LSP: Format Document" })
    end,
    opts = {
      servers = servers,
    },
  },
}
