return {
  -- catppuccino theme
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
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
