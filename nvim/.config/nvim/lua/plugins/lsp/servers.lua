return {
  csharp_ls = false,

  omnisharp = {
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/OmniSharp" },
    enable_editorconfig_support = true,
    enable_roslyn_analyzers = true,
    organize_imports_on_format = true,
    enable_import_completion = true,
    on_attach = function(client)
      client.server_capabilities.semanticTokensProvider = nil
    end,
  },
  ruby_lsp = {
    -- especifique quaisquer filetypes se quiser forçar; por padrão já inclui "ruby"
    filetypes = { "ruby", "rb" },

    -- init_options conforme a spec do Ruby LSP
    init_options = {
      -- Exemplo: usar o formatter "standard" e o linter "standard"
      formatter = "standard",
      linters = { "standard" },

      -- Para desabilitar prompt de migrations pending, por ex.
      addonSettings = {
        ["Ruby LSP Rails"] = {
          enablePendingMigrationsPrompt = false,
        },
      },
    },
  },
  tsserver = {}, -- Suporte para TypeScript/JavaScript
  eslint = {}, -- Integração com ESLint
  html = {}, -- HTML
  cssls = {}, -- CSS
  tailwindcss = {}, -- TailwindCSS
}
