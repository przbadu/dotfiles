### how to setup
Use [stow](https://www.gnu.org/software/stow/) to create symlinks to the dotfiles in your home directory. 

```sh
brew install stow
```

```sh
# add tpm (Tmux plugin manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# symlink dotfiles
stow .
```
