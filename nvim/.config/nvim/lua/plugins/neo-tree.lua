return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = false, -- mostra/oculta arquivos ocultos com `<leader>H`
        hide_dotfiles = true,
        hide_gitignored = true,
        hide_by_name = {
          "bin",
          "obj",
        },
        never_show = {
          ".DS_Store",
          "thumbs.db",
        },
      },
    },
  },
}
