-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- vim-test strategy configuration
vim.cmd([[
      let test#strategy = "neovim"
      let test#neovim#term_position = "vert"
      ]])

-- disable autoformat
vim.g.autoformat = false -- false
