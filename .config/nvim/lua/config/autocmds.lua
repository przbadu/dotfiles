-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable autoformat for lua files

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "rb", "haml", "erb", "scss", "js" },
  callback = function()
    vim.b.autoformat = false
  end,
})

-- Enable autoread and set up checking triggers for VSCode-like auto-reload behavior
vim.o.autoread = true

-- Primary auto-reload: Check for file changes on key events
-- BufEnter: When switching to a buffer
-- CursorHold: After 'updatetime' milliseconds of inactivity
-- CursorHoldI: Same as CursorHold but in insert mode
-- FocusGained: When Neovim window gains focus
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { "*" },
})

-- Enhanced responsiveness: Check for file changes during cursor movement
-- CursorMoved: When cursor moves in normal mode
-- CursorMovedI: When cursor moves in insert mode
-- This makes file reloading more immediate, similar to VSCode behavior
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  callback = function()
    if vim.fn.mode() ~= 'c' then
      vim.cmd('checktime')
    end
  end,
})

-- Set shorter updatetime for better responsiveness
vim.o.updatetime = 250
