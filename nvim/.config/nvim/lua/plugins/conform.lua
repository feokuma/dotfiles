return {
  "stevearc/conform.nvim",
  optional = true,
  opts = {
    formatters_by_ft = {
      cs = { "csharpier" },
    },
    formatters = {
      csharpier = {
        command = "csharpier",
        args = { "format", vim.api.nvim_buf_get_name(0) },
        stdin = false,
      },
    },
  },
}
