return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      omnisharp = {
        handlers = {
          ["textDocument/definition"] = require("omnisharp_extended").handler,
        },
        enable_import_completion = true,
        organize_imports_on_format = true,
        enable_roslyn_analyzers = true,
      },
    },
  },
}
