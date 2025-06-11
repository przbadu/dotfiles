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

# Function to detect operating system
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command_exists apt; then
      echo "ubuntu"
    else
      echo "linux"
    fi
  else
    echo "unknown"
  fi
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

# Configure zsh as default shell
install_zsh() {
  log "Checking zsh installation..."
  if ! command_exists zsh; then
    warn "zsh not found! It should be installed via package manager."
    warn "Please ensure zsh is in your packages file and re-run the script."
    return 1
  else
    log "zsh already installed, Great!"
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

# Check neovim installation
install_neovim() {
  log "Checking Neovim installation..."
  if ! command_exists nvim; then
    warn "Neovim not found! It should be installed via package manager."
    warn "Please ensure neovim is in your packages file and re-run the script."
    return 1
  else
    log "Neovim already installed, Great!"
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

# Install LazyVim configuration
install_lazyvim() {
  log "Checking LazyVim installation..."
  if ! dir_exists "${HOME}/.config/nvim"; then
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

# Install packages from OS-specific package files
install_packages() {
  local os=$(detect_os)
  local packages_file=""

  case $os in
  "macos")
    packages_file="packages-macos.txt"
    ;;
  "ubuntu")
    packages_file="packages-linux.txt"
    ;;
  *)
    warn "Unsupported OS: $os. Skipping package installation."
    return
    ;;
  esac

  if [ ! -f "$packages_file" ]; then
    warn "$packages_file not found, skipping package installation"
    return
  fi

  log "Installing packages from $packages_file for $os..."

  case $os in
  "macos")
    install_macos_packages "$packages_file"
    ;;
  "ubuntu")
    install_ubuntu_packages "$packages_file"
    ;;
  esac
}

# Install packages on macOS using Homebrew
install_macos_packages() {
  local packages_file="$1"

  # Install Homebrew if not present
  if ! command_exists brew; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for current session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  # Read packages from file and install
  while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
      continue
    fi

    # Check if it's a custom command (starts with a command)
    if [[ "$line" =~ ^(curl|wget|brew|sudo|/bin/bash).* ]]; then
      log "Executing custom command: $line"
      eval "$line" || warn "Failed to execute custom command: $line"
    # Check if it's a cask package (GUI)
    elif [[ "$line" =~ ^cask: ]]; then
      package=$(echo "$line" | sed 's/^cask: *//')
      log "Installing cask: $package"
      brew install --cask "$package" || warn "Failed to install cask: $package"
    else
      log "Installing package: $line"
      brew install "$line" || warn "Failed to install package: $line"
    fi
  done <"$packages_file"
}

# Install packages on Ubuntu using apt and snap
install_ubuntu_packages() {
  local packages_file="$1"

  # Update package list
  log "Updating package list..."
  sudo apt update

  # Install snapd if not present
  if ! command_exists snap; then
    log "Installing snapd..."
    sudo apt install -y snapd
  fi

  # Read packages from file and install
  while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
      continue
    fi

    # Check if it's a custom command (starts with sudo, curl, wget, etc.)
    if [[ "$line" =~ ^(sudo|curl|wget|apt|dpkg|/bin/bash).* ]]; then
      log "Executing custom command: $line"
      eval "$line" || warn "Failed to execute custom command: $line"
    # Check if it's a snap package
    elif [[ "$line" =~ ^snap: ]]; then
      package=$(echo "$line" | sed 's/^snap: *//')
      log "Installing snap package: $package"
      sudo snap install $package || warn "Failed to install snap package: $package"
    else
      log "Installing apt package: $line"
      sudo apt install -y "$line" || warn "Failed to install apt package: $line"
    fi
  done <"$packages_file"
}

# Copy dotfiles
copy_dotfiles() {
  # Check if stow is installed first
  if ! command_exists stow; then
    error "GNU Stow is not installed. Please install stow first."
    error "On Ubuntu/Debian: sudo apt install stow"
    error "On macOS: brew install stow"
    return 1
  fi

  # Handle existing dotfiles directory
  if [ -d "$HOME/dotfiles" ]; then
    warn "Existing dotfiles directory found at $HOME/dotfiles"
    warn "To get the latest files from remote, please run 'git pull' inside the dotfiles directory and re-run this script"
    log "Using existing dotfiles to symlink"
    cd "$HOME/dotfiles"
  else
    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
      warn "Your $HOME/.zshrc is copied to $HOME/.zshrc.bak"
      mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    fi

    log "Cloning dotfiles to ~/dotfiles"
    git clone git@github.com:przbadu/dotfiles.git ~/dotfiles
    cd "$HOME/dotfiles"
  fi

  log "Symlinking dotfiles"
  # update existing files
  stow --adopt --ignore=setup.sh --ignore=packages-linux.txt --ignore=packages-macos.txt .

  if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
    log "Install tmux package manager inside ~/.tmux/plugins/tpm"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
}

# Main installation process
main() {
  log "Starting installation process..."

  # Install packages from packages.txt first
  install_packages

  # Configure zsh as default shell (zsh installed via package manager)
  install_and_select_zsh

  # only install debian-specific packages if on a Debian-based system
  if command_exists apt; then
    install_lazygit
    install_tmux
  else
    warn "Lazygit and tmux are only installed on Debian-based systems. You need to install them manually."
  fi

  setup_mise
  install_languages
  configure_git
  install_neovim
  install_lazyvim
  copy_dotfiles

  log "Installation completed successfully!"

  log "If you prefer to run docker without sudo you can run following commands:\nsudo groupadd docker && sudo usermod -aG docker $USER && newgrp docker\n\n"

  # Show appropriate completion message based on shell choice
  if [[ "${RC_FILE}" == *"zshrc"* ]]; then
    log "Please run 'zsh' or restart your terminal for all changes to take effect."
  else
    log "Please run 'source ${RC_FILE}' or restart your terminal for all changes to take effect."
  fi
}

# Run the script
main
