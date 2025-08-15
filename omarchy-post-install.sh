#!/bin/sh

# Install zsh and change shell
sudo pacman -S zsh
chsh -s $(which zsh)

# Copy .zshrc, .zshrc.*, .tmux.conf files to home director
# rm -rf dotfiles
# git clone https://github.com/przbadu/dotfiles
cp .config/nvim/lua/config/autocmds.lua $HOME/.config/nvim/lua/config/autocmds.lua
cp .config/nvim/lua/config/keymaps.lua $HOME/.config/nvim/lua/config/keymaps.lua
cp .config/nvim/lua/config/options.lua $HOME/.config/nvim/lua/config/options.lua

cp .config/nvim/lua/plugins/git-blame.lua $HOME/.config/nvim/lua/plugins/git-blame.lua
cp .config/nvim/lua/plugins/rails.lua $HOME/.config/nvim/lua/plugins/rails.lua
cp .config/nvim/lua/plugins/test.lua $HOME/.config/nvim/lua/plugins/test.lua

# tmux plugin manager
if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
  log "Install tmux package manager inside ~/.tmux/plugins/tpm"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "Change your terminal font size in: $HOME/.config/alacritty/alacritty.toml"
