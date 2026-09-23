-- Tema Catppuccin Mocha.
--
-- Mesma paleta Catppuccin usada no tema visual do desktop (Quickshell),
-- para consistência entre terminal e shell. O `lazy = false` garante que
-- o tema carregue antes dos start plugins e evita flash de cores erradas.

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    flavour = "mocha",
    config = function()
      local catppuccin = require("catppuccin")
      catppuccin.setup({
        flavour = "mocha",
        transparent_background = false,
        term_transparency = false,
        integrations = {
          cmp = true,
          gitsigns = true,
          mini = true,
          neotree = true,
          telemetry = false,
          which_key = true,
        },
      })
      catppuccin.load()
    end,
  },
}
