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

git clone git@github.com:przbadu/dotfiles.git ~/dotfiles
cd dotfiles

# symlink dotfiles
stow .
```

### Setup

* Install oh-my-zsh https://ohmyz.sh/#install
  ```
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ```

* Install zsh-autosuggestion from https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh
```
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```
* zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md#oh-my-zsh
```
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```
* Jetbrains Mono nerd font https://github.com/ryanoasis/nerd-fonts?tab=readme-ov-file#option-1-release-archive-download
```
curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xvf JetBrainsMono.tar.xz
sudo mkdir /usr/local/share/fonts/JetBrains
sudo mv *.ttf /usr/local/share/fonts/JetBrains
# if fontconfig is missing install it
sudo apt install fontconfig
sudo fc-cache -f -v
```
* 
3. powerlevel10k https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#oh-my-zsh
```
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
source ~/.zshrc
```
