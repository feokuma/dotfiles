return {
  "CopilotC-Nvim/CopilotChat.nvim",
  cmd = { "CopilotChat", "CopilotChatFix", "CopilotChatExplain", "CopilotChatEdit" },
  dependencies = {
    { "zbirenbaum/copilot.lua" }, -- Certifique-se de que já está usando o plugin oficial do Copilot
  },
  opts = {
    show_help = true,
    mappings = {
      complete = {
        detail = "Use <Tab> para completar, <C-e> para cancelar",
        insert = "<Tab>",
      },
      close = "<Esc>",
      submit_prompt = "<C-Enter>",
    },
  },
  keys = {
    { "<leader>cc", ":CopilotChat<CR>", desc = "Abrir Copilot Chat" },
    { "<leader>ce", ":CopilotChatEdit<CR>", desc = "Editar com Copilot Chat" },
    { "<leader>cf", ":CopilotChatFix<CR>", desc = "Tentar corrigir código" },
    { "<leader>cx", ":CopilotChatExplain<CR>", desc = "Explicar código" },
  },
}
