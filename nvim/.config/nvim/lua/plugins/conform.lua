return {
  "stevearc/conform.nvim",
  optional = true,
  opts = {
    formatters_by_ft = {
      cs = { "csharpier" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      ruby = { "rubocop" },
    },
    formatters = {
      csharpier = {
        command = "csharpier",
        args = { "format", vim.api.nvim_buf_get_name(0) },
        stdin = false,
      },
      rubocop = {
        command = "bundle",
        args = { "exec", "rubocop", "--auto-correct", "--stdin", vim.api.nvim_buf_get_name(0) },
        stdin = true,
      },
    },
  },
}
