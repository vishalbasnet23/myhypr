-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "<CR>", "o", { desc = "Insert Line Below" })

map("n", "<S-CR>", "O", { desc = "Insert Line Above" })

map("n", "<C-a>", "ggVG", opts)

map("n", "<C-S-d>", "yyp", opts)

map("n", "<leader>w", "<cmd>bd<CR>", { desc = "Close buffer", silent = true })

map("i", "<C-S-k>", "<Esc>:move .-2<CR>==gi", { desc = "Move Line Up" })
map("n", "<C-S-k>", "<cmd>move .-2<CR>==", { desc = "Move Line Up" })
map("v", "<C-S-k>", ":move '<-2<CR>gv=gv", { desc = "Move Selection Up" })

-- Move line/selection down
map("n", "<C-S-j>", "<cmd>move .+1<CR>==", { desc = "Move Line Down" })
map("i", "<C-S-j>", "<Esc>:move .+2<CR>==gi", { desc = "Move Line Down" })
map("v", "<C-S-j>", ":move '>+1<CR>gv=gv", { desc = "Move Selection Down" })
-- Save mapping for all modes
map({ "n", "i", "v", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
