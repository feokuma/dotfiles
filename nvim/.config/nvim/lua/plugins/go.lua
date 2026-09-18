-- Suporte a desenvolvimento Go (projeto rn-toolchain).
--
-- Usa o extra oficial do LazyVim `lang.go` (já fornece):
--   - gopls (LSP) com fnaguras avançadas (staticcheck, codelenses, hints)
--   - treesitter para go/gomod/gowork/gosum
--   - conform.nvim: formatters goimports + gofumpt
--   - nvim-lint: golangci-lint
--   - nvim-dap + delve (debugging) e neotest (testes Go)
--
-- Aqui apenas garantimos que o `gopls` (language server) e utilitários
-- úteis sejam instalados via mason-tool-installer, o mesmo padrão já usado
-- no quickshell.lua para Lua.
return {
  -- Extra oficial do LazyVim para Go.
  { import = "lazyvim.plugins.extras.lang.go" },

  -- Garante as ferramentas Go via mason-tool-installer.
  -- Obs.: o extra já garante goimports/gofumpt/golangci-lint/delve;
  -- aqui adicionamos gopls (indispensável) e alguns extras úteis.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local tools = { "gopls", "staticcheck" }
      for _, tool in ipairs(tools) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end
    end,
  },
}