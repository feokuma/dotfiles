return {
  "github/copilot.vim",
  event = "InsertEnter",
  opts = {
    suggestion = { enabled = true },
    panel = { enabled = true },
  },
  config = function(_, opts)
    require("copilot").setup(opts)
  end,
}
