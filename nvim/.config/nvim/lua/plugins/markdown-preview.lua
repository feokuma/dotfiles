return {
  "iamcco/markdown-preview.nvim",
  ft = { "markdown" },
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
  config = function()
    vim.g.mkdp_auto_start = 0 -- não abre automaticamente
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_browser = "" -- ou "firefox", "brave", etc
    vim.g.mkdp_theme = "dark"
    vim.g.mkdp_auto_start = 1
  end,
  keys = {
    { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
  },
}
