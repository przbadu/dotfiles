#!/usr/bin/env bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global RC_FILE variable (will be set based on shell choice)
RC_FILE=""

# Function to log messages
log() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${GREEN}$1${NC}"
}

# Function to log warnings
warn() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${YELLOW}WARNING: $1${NC}"
}

# Function to log errors
error() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${RED}ERROR: $1${NC}"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check if a directory exists
dir_exists() {
  [ -d "$1" ]
}

# Function to backup a directory if it exists
backup_dir() {
  local dir=$1
  if dir_exists "$dir"; then
    if ! dir_exists "${dir}.bak"; then
      log "Backing up ${dir} to ${dir}.bak"
      mv "$dir" "${dir}.bak"
    else
      warn "Backup ${dir}.bak already exists, skipping backup"
    fi
  fi
}

# Function to select shell
install_and_select_zsh() {
  RC_FILE="${HOME}/.zshrc"
  log "Installing and configuring zsh..."
  install_zsh
}

# System update and dependencies
install_debian_dependencies() {
  log "Checking and installing system dependencies..."
  if ! dpkg -l | grep -q build-essential; then
    log "Installing build-essential and other dependencies..."
    sudo apt update
    sudo apt install -y build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev libpq-dev tmux
  else
    warn "Dependencies already installed, skipping..."
  fi
}

# Install zsh and oh-my-zsh
install_zsh() {
  log "Checking zsh installation..."
  if ! command_exists zsh; then
    log "Installing zsh..."
    sudo apt install -y zsh
  else
    warn "zsh already installed, Great!"
  fi

  # Instead of automatically changing shell, provide instructions
  if [ "$SHELL" != "$(which zsh)" ]; then
    log "To set zsh as your default shell, run:"
    echo "sudo chsh -s $(which zsh) $USER"

    # Prompt user if they want to change shell now
    read -p "Would you like to change your default shell to zsh now? (y/N) " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      log "Changing default shell to zsh..."
      sudo chsh -s "$(which zsh)" "$USER"
    else
      log "Skipping shell change. You can change it later using the command above."
    fi
  fi
}

# Setup mise
setup_mise() {
  if ! command_exists mise; then
    log "Installing mise..."
    curl https://mise.run | sh

    # Get shell name from RC_FILE
    local shell_name=$(basename "${RC_FILE}" | sed 's/\.[^.]*$//')

    if ! grep -q "mise activate" "${RC_FILE}"; then
      echo "eval \"\$(${HOME}/.local/bin/mise activate ${shell_name})\"" >>"${RC_FILE}"
    fi

    # Export PATH and activate mise for current session
    export PATH="${HOME}/.local/bin:$PATH"

    # Source mise activation for current session
    if [ -f "${HOME}/.local/bin/mise" ]; then
      eval "$("${HOME}/.local/bin/mise" activate bash)"

      # Verify mise is now available
      if ! command_exists mise; then
        error "mise installation failed or not in PATH. Please check installation and try again."
        exit 1
      fi
    else
      error "mise binary not found after installation. Please check installation and try again."
      exit 1
    fi
  else
    warn "mise already installed, skipping..."
  fi
}

install_ruby() {
  read -p "Would you like to install ruby? (y/N) " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    read -p "Enter Ruby version (default: 3): " RUBY_VERSION
    RUBY_VERSION=${RUBY_VERSION:-3}
    log "Installing Ruby ${RUBY_VERSION}..."
    mise use --global "ruby@${RUBY_VERSION}"

    # Export PATH for gem command
    export PATH="$HOME/.local/share/mise/installs/ruby/$RUBY_VERSION/bin:$PATH"

    if command_exists gem; then
      log "Updating RubyGems system..."
      gem update --system
    else
      warn "gem command not found after Ruby installation, skipping system update"
    fi
  fi
}

# Lets install node with nvm because (mise install node are causing trouble with MCP servers)
install_nodejs() {
  read -p "Would you like to install Nodejs? (y/N) " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    log "Install NVM: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    # Load nvm to the current shell
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

    read -p "Enter Node.js version (default): " NODE_VERSION
    NODE_VERSION=${NODE_VERSION:node}
    log "Installing Node.js ${NODE_VERSION}..."
    mise use --global "node@${NODE_VERSION}"
    npm install --global yarn@latest
  fi
}

# Install Ruby and Node.js
install_languages() {
  log "Checking Ruby and Node.js installations..."

  # Prompt for versions if not already installed
  if ! command_exists ruby; then
    install_ruby
  else
    warn "Ruby is already installed"
  fi

  if ! command_exists node; then
    install_nodejs
  else
    warn "Node.js already installed, skipping..."
  fi
}

# Configure git
configure_git() {
  log "Checking git configuration..."
  if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]; then
    read -p "Enter your git username: " GIT_USERNAME
    read -p "Enter your git email: " GIT_EMAIL
    git config --global color.ui true
    git config --global user.name "${GIT_USERNAME}"
    git config --global user.email "${GIT_EMAIL}"
  else
    warn "Git already configured, skipping..."
  fi
}

# Install neovim
install_neovim() {
  log "Checking Neovim installation..."
  if ! command_exists nvim; then
    log "Installing Neovim..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    rm -f nvim-linux-x86_64.tar.gz

    # Add to PATH in RC_FILE if not already there
    if ! grep -q "/opt/nvim-linux-x86_64/bin" "${RC_FILE}"; then
      echo 'export PATH="/opt/nvim-linux-x86_64/bin:$PATH"' >>"${RC_FILE}"
    fi

    # Export PATH for current session
    export PATH="/opt/nvim-linux-x86_64/bin:$PATH"
  else
    warn "Neovim already installed, skipping..."
  fi
}

# Function to setup custom neovim config
setup_custom_neovim_config() {
  log "Setting up custom Neovim configurations..."

  # Create directories if they don't exist
  mkdir -p "${HOME}/.config/nvim/lua/config"
  mkdir -p "${HOME}/.config/nvim/lua/plugins"

  # Download and extract templates
  log "Downloading Neovim templates..."
  git clone https://github.com/przbadu/dotfiles.git

  # Copy config files
  log "Copying config files..."
  cp -r dotfiles/templates/nvim/lua/config/*.* $HOME/.config/nvim/lua/config/

  # Copy plugin files
  log "Copying plugin files..."
  cp -r dotfiles/templates/nvim/lua/plugins/*.* $HOME/.config/nvim/lua/plugins/

  # Cleanup
  rm -rf dotfiles
  log "Custom Neovim configuration setup completed."
}

# Modify install_lazyvim function to include custom config setup
install_lazyvim() {
  log "Checking LazyVim installation..."
  if ! dir_exists "${HOME}/.config/nvim"; then
    log "Installing LazyVim dependencies..."
    sudo apt install -y git fzf curl ripgrep

    log "Backing up existing Neovim configurations..."
    backup_dir "${HOME}/.config/nvim"
    backup_dir "${HOME}/.local/share/nvim"
    backup_dir "${HOME}/.local/state/nvim"
    backup_dir "${HOME}/.cache/nvim"

    log "Installing LazyVim..."
    git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"
    rm -rf "${HOME}/.config/nvim/.git"

    # Add custom config setup here
    setup_custom_neovim_config
  else
    warn "LazyVim configuration already exists, skipping..."
  fi
}

# Install lazygit
install_lazygit() {
  log "Checking lazygit installation..."
  if ! command_exists lazygit; then
    log "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t /usr/local/bin/
    rm -f lazygit.tar.gz lazygit
  else
    warn "lazygit already installed, skipping..."
  fi
}

# Install and setup tmux
install_tmux() {
  log "Installing tmux..."
  sudo apt install tmux -y
}

# Copy dotfiles
copy_dotfiles() {
  if [ -f "$HOME/.zshrc" ]; then
    warn "Your $HOME/.zshrc is copied to $HOME/.zshrc.bak"
    mv $HOME/.zshrc $HOME/.zshrc.bak
  fi

  log "Installing stow to symlink dotfiles"
  sudo apt install -y stow

  log "Cloning dotfiles to ~/dotfiles"
  git clone git@github.com:przbadu/dotfiles.git ~/dotfiles
  cd ~/dotfiles/

  log "Symlinking dotfiles"
  # update existing files
  stow --adapt --ignore=setup .

  if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
    log "Install tmux package manager inside ~/.tmux/plugins/tpm"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
}

# Main installation process
main() {
  log "Starting installation process..."

  # only install debian dependencies if on a Debian-based system
  if command_exists apt; then
    install_debian_dependencies
    install_lazygit
    install_tmux
    # First, let user select their preferred shell
    install_and_select_zsh
  else
    warn "Lazygit, tmux, and other dependencies are only installed on Debian-based systems. You need to install them manually."
    log "Please make sure you have installed zsh and zsh is your default shell."
  fi

  setup_mise
  install_languages
  configure_git
  install_neovim
  install_lazyvim
  copy_dotfiles

  log "Installation completed successfully!"

  # Show appropriate completion message based on shell choice
  if [[ "${RC_FILE}" == *"zshrc"* ]]; then
    log "Please run 'zsh' or restart your terminal for all changes to take effect."
  else
    log "Please run 'source ${RC_FILE}' or restart your terminal for all changes to take effect."
  fi
}

# Run the script
main
