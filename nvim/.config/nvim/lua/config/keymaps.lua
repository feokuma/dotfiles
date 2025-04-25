-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymap = vim.keymap
local opts = { noremap = true, silent = true }

keymap.set("n", "<C-a>", "gg<S-v>G")

keymap.set("i", "<C-l>", function()
  return vim.fn["codeium#Accept"]()
end, { expr = true, silent = true })
keymap.set("i", "<C-]>", function()
  return vim.fn["codeium#CycleCompletions"](-1)
end, { expr = true, silent = true })
keymap.set("i", "<C-x>", function()
  return vim.fn["codeium#Clear"]()
end, { expr = true, silent = true })

keymap.set("n", "<leader>cf", ":!dotnet format<CR>", { desc = "Format .NET core" })
