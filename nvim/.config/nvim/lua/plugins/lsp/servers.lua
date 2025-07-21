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
}
