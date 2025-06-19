-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Tmux navigation
local function tmux_navigate(direction)
  local tmux_direction = { h = "L", j = "D", k = "U", l = "R" }
  local at_edge = {
    h = function() return vim.fn.winnr() == vim.fn.winnr("h") end,
    j = function() return vim.fn.winnr() == vim.fn.winnr("j") end,
    k = function() return vim.fn.winnr() == vim.fn.winnr("k") end,
    l = function() return vim.fn.winnr() == vim.fn.winnr("l") end,
  }
  
  if at_edge[direction]() then
    vim.fn.system("tmux select-pane -" .. tmux_direction[direction])
  else
    vim.cmd("wincmd " .. direction)
  end
end

vim.keymap.set("n", "<C-h>", function() tmux_navigate("h") end, { desc = "Go to Left Window or Tmux Pane" })
vim.keymap.set("n", "<C-j>", function() tmux_navigate("j") end, { desc = "Go to Lower Window or Tmux Pane" })
vim.keymap.set("n", "<C-k>", function() tmux_navigate("k") end, { desc = "Go to Upper Window or Tmux Pane" })
vim.keymap.set("n", "<C-l>", function() tmux_navigate("l") end, { desc = "Go to Right Window or Tmux Pane" })

local keymap = vim.api.nvim_set_keymap
local default_opts = { noremap = true, silent = true }

-- Paste over currently selected text without yanking it
keymap("v", "p", '"_dP', default_opts)

-- vim-test
-- Define key mappings for test commands
keymap("n", "<leader>tt", ":TestNearest<CR>", default_opts)
keymap("n", "<leader>tf", ":TestFile<CR>", default_opts)
keymap("n", "<leader>ts", ":TestSuite<CR>", default_opts)
keymap("n", "<leader>tl", ":TestLast<CR>", default_opts)
keymap("n", "<leader>tg", ":TestVisit<CR>", default_opts)

-- autorun current ruby file
keymap("n", "<leader>rr", ":term ruby % <CR>", default_opts)

-- pyright ignore line
vim.keymap.set("n", "<leader>ig", "A # pyright: ignore<Esc>")

-- checkbox
vim.keymap.set("n", "<leader>ty", [[:s/\[\s\]/[x]/<cr>]], { silent = true })
vim.keymap.set("n", "<leader>tu", [[:s/\[x\]/[ ]/<cr>]], { silent = true })

-- jj to escape
vim.keymap.set("i", "jj", "<ESC>", { silent = true })
