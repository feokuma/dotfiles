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
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {},
        eslint = {},
        tailwindcss = {},
      },
    },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function(_, opts)
      local null_ls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.diagnostics.eslint,
      })

      table.insert(
        opts.sources,
        null_ls.builtins.formatting.custom.with({
          command = "svgo",
          args = { "--input", "$FILENAME" },
          filetypes = { "svg" },
        })
      )
    end,
  },
}
