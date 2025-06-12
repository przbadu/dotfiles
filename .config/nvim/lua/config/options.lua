-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.cmd([[
      let test#strategy = "neovim"
      let test#neovim#term_position = "vert"
      ]])

vim.g.autoformat = false -- true/false disable autoformat

vim.o.conceallevel = 2 -- set conceal level for obsidian plugin
