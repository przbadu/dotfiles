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
select_shell() {
    log "Select your preferred shell:"
    log "1) zsh (default)"
    log "2) bash"
    read -p "Enter choice [1-2]: " shell_choice
    shell_choice=${shell_choice:-1}
    
    case "${shell_choice}" in
        1)
            RC_FILE="${HOME}/.zshrc"
            log "Installing and configuring zsh..."
            install_zsh
            ;;
        2)
            RC_FILE="${HOME}/.bashrc"
            log "Using bash with ${RC_FILE}"
            ;;
        *)
            log "Invalid choice '${shell_choice}'. Defaulting to zsh..."
            RC_FILE="${HOME}/.zshrc"
            install_zsh
            ;;
    esac
}

# System update and dependencies
install_dependencies() {
  log "Checking and installing system dependencies..."
  if ! dpkg -l | grep -q build-essential; then
    log "Installing build-essential and other dependencies..."
    sudo apt update
    sudo apt install -y build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev tmux
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
        # Use my .zshrc file
        curl -fsSL https://raw.githubusercontent.com/przbadu/dotfiles/refs/heads/main/ref-later/.zshrc > $HOME/.zshrc
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
        
        # Get shell name from RC_FILE
        local shell_name=$(basename "${RC_FILE}" | sed 's/\.[^.]*$//')
        
        if ! grep -q "mise activate" "${RC_FILE}"; then
            echo "eval \"\$(${HOME}/.local/bin/mise activate ${shell_name})\"" >> "${RC_FILE}"
            # Export PATH for current session
            export PATH="${HOME}/.local/bin:$PATH"
            # Source mise directly
            eval "$("${HOME}/.local/bin/mise" activate ${shell_name})"
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

    # Export PATH for gem command
    export PATH="$HOME/.local/share/mise/installs/ruby/$RUBY_VERSION/bin:$PATH"

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
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    sudo rm -rf /opt/nvim-linux64
    sudo tar -C /opt -xzf nvim-linux64.tar.gz
    rm -f nvim-linux64.tar.gz

    # Add to PATH in RC_FILE if not already there
    if ! grep -q "/opt/nvim-linux64/bin" "${RC_FILE}"; then
        echo 'export PATH="/opt/nvim-linux64/bin:$PATH"' >> "${RC_FILE}"
    fi
    
    # Export PATH for current session
    export PATH="/opt/nvim-linux64/bin:$PATH"
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

# Install and setup tmux
install_tmux() {
  log "Installing tmux..."
  sudo apt install tmux -y
}

# Copy dotfiles
copy_dotfiles() {
  log "Setup tmux"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  curl -sSL https://raw.githubusercontent.com/przbadu/dotfiles/refs/heads/main/templates/.tmux.conf > .tmux.conf

  if [[ "${RC_FILE}" == *"zshrc"* ]]; then
    log "setup ZSH"
    # zsh-autosuggestions
    if [ ! -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    fi

    # zsh-syntax-highlighting
    if [ ! -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    fi

    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "${HOME}/.zshrc"
    curl -sSL https://raw.githubusercontent.com/przbadu/dotfiles/refs/heads/main/templates/.zshrc > .zshrc.user
    echo -e "source ~/.zshrc.user" >> "${HOME}/.zshrc"
  fi

  source $HOME/$RC_FILE
}

# Main installation process
main() {
  log "Starting installation process..."

  # First, let user select their preferred shell
  select_shell
  
  install_dependencies
  setup_mise
  install_languages
  configure_git
  install_neovim
  install_lazyvim
  install_lazygit
  install_tmux
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