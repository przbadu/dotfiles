#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# System update and dependencies
install_dependencies() {
  log "Checking and installing system dependencies..."
  if ! dpkg -l | grep -q build-essential; then
    log "Installing build-essential and other dependencies..."
    sudo apt update
    sudo apt install -y build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev
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
        warn "zsh already installed, skipping..."
    fi

    # Backup existing .zshrc if it exists
    if [ -f "${HOME}/.zshrc" ]; then
        log "Backing up existing .zshrc..."
        mv "${HOME}/.zshrc" "${HOME}/.zshrc.backup"
    fi

    # Install oh-my-zsh if not already installed
    if [ ! -d "${HOME}/.oh-my-zsh" ]; then
        log "Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        warn "oh-my-zsh already installed, skipping..."
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
        if ! grep -q "mise activate" "${HOME}/.zshrc"; then
            echo 'eval "$(/home/przbadu/.local/bin/mise activate bash)"' >> "${HOME}/.zshrc"
            # Export PATH for current session
            export PATH="${HOME}/.local/bin:$PATH"
            # Source mise directly
            eval "$("${HOME}/.local/bin/mise" activate bash)"
        fi
    else
        warn "mise already installed, skipping..."
    fi
}

# Install Ruby and Node.js
install_languages() {
  log "Checking Ruby and Node.js installations..."

  # Prompt for versions if not already installed
  if ! command_exists ruby; then
    read -p "Enter Ruby version (default: 3): " RUBY_VERSION
    RUBY_VERSION=${RUBY_VERSION:-3}
    log "Installing Ruby ${RUBY_VERSION}..."
    mise use --global "ruby@${RUBY_VERSION}"

    if command_exists gem; then
      log "Updating RubyGems system..."
      gem update --system
    else
      warn "gem command not found after Ruby installation, skipping system update"
    fi
  else
    warn "Ruby already installed, skipping..."
  fi

  if ! command_exists node; then
    read -p "Enter Node.js version (default: 22.13.0): " NODE_VERSION
    NODE_VERSION=${NODE_VERSION:-22.13.0}
    log "Installing Node.js ${NODE_VERSION}..."
    mise use --global "node@${NODE_VERSION}"
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
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    rm -f nvim-linux-x86_64.tar.gz
    echo 'export PATH="/opt/nvim-linux-x86_64/bin:$PATH"' >>~/.zshrc
  else
    warn "Neovim already installed, skipping..."
  fi
}

# Install LazyVim
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

# Main installation process
main() {
  log "Starting installation process..."

  install_dependencies
  install_zsh
  setup_mise
  install_languages
  configure_git
  install_neovim
  install_lazyvim
  install_lazygit

  if ! grep -q "/opt/nvim-linux64/bin" "${HOME}/.zshrc"; then
    echo 'export PATH="/opt/nvim-linux64/bin:$PATH"' >> "${HOME}/.zshrc"
  fi

  log "Installation completed successfully!"
  log "Please restart your terminal for all changes to take effect."
}

# Run the script
main