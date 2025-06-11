-- use <ctrl>c <ctrl>c to run selected line
return {
    {
      "jpalardy/vim-slime",
      config = function()
        vim.g.slime_target = "tmux"
        vim.g.slime_bracketed_paste = 1
      end
    }
  }