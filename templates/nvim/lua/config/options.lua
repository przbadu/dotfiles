-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- vim-test strategy configuration
vim.cmd([[
      let test#strategy = "neovim"
      let test#neovim#term_position = "vert"
      ]])

vim.g.autoformat = false -- true/false disable autoformat

vim.o.conceallevel = 2 -- set conceal level for obsidian plugin

-- Setup NVIM for jupyter notebook and ML IDE
-- TODO: it expect ai-learning conda environment, we need to make this dynamic
vim.g.python3_host_prog = "/home/user/miniconda3/envs/ai-learning/bin/python"
-- nvim.slime configuration to auto detect tmux pane where `jupyter console --kernel=python3` is running.
vim.g.slime_target = "tmux"
vim.g.slime_default_config = { socket_name = "default", target_pane = "{last}" }