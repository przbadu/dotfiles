### how to setup
Use [stow](https://www.gnu.org/software/stow/) to create symlinks to the dotfiles in your home directory. 

**OSX**

```sh
brew install stow
```

**Linux**

```sh
sudo apt install stow
```

**Clone and use dotfile**

```sh
# add tpm (Tmux plugin manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

git clone https://github.com/przbadu/dotfiles ~/dotfiles
cd dotfiles

# symlink dotfiles
stow .
```
