return {
  -- Adicione o plugin Prettier
  {
    "MunifTanjim/prettier.nvim",
    config = function()
      require("prettier").setup({
        bin = "prettier", -- ou 'prettierd' se você tiver o prettier daemon instalado
        filetypes = {
          "javascript",
          "typescript",
          "css",
          "html",
          "json",
          "markdown",
        },
      })
    end,
  },
}
