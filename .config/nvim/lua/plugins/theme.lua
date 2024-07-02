return {
  -- catppuccino theme
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  -- one dark theme
  {
    "navarasu/onedark.nvim",
    name = "onedark",
    priority = 1000,
    opts = {
      style = "darker",
    },
  },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "catppuccin-latte",
      colorscheme = "catppuccin",
      -- colorscheme = "onedark",
    },
  },
}
