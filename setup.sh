#!/usr/bin/env zsh

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global RC_FILE variable (will be set based on shell choice)
RC_FILE=""

# Global flag for CLI-only installation
CLI_ONLY=false

# Global flag for forcing reinstallation
FORCE_REINSTALL=false

# Global flag for skipping package installation
SKIP_PACKAGES=false

# Global arrays to track installations and backups for rollback
INSTALLED_PACKAGES=()
CREATED_BACKUPS=()
TEMP_DIRECTORIES=()
INSTALLED_BINARIES=()

# State management file
STATE_FILE="${HOME}/.dotfiles-setup-state"

# State management functions
load_state() {
  if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE" 2>/dev/null || true
  fi
}

save_state() {
  local component="$1"
  local version="$2"

  # Create state file if it doesn't exist
  touch "$STATE_FILE"

  # Remove any existing entry for this component
  grep -v "^${component}_" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
  mv "${STATE_FILE}.tmp" "$STATE_FILE" 2>/dev/null || true

  # Add new state
  echo "${component}_COMPLETED=true" >> "$STATE_FILE"
  echo "${component}_VERSION=\"${version}\"" >> "$STATE_FILE"
  echo "${component}_TIMESTAMP=$(date +%s)" >> "$STATE_FILE"
}

is_completed() {
  local component="$1"
  local var_name="${component}_COMPLETED"

  if [ "$FORCE_REINSTALL" = true ]; then
    return 1
  fi

  load_state
  eval "local completed=\$$var_name"
  [ "$completed" = "true" ]
}

get_state_version() {
  local component="$1"
  local var_name="${component}_VERSION"

  load_state
  eval "echo \$$var_name"
}

clear_state() {
  local component="$1"
  if [ -f "$STATE_FILE" ]; then
    grep -v "^${component}_" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
    mv "${STATE_FILE}.tmp" "$STATE_FILE" 2>/dev/null || true
  fi
}

# Enhanced checking functions for better performance
is_git_configured() {
  [ -n "$(git config --global user.name 2>/dev/null)" ] && [ -n "$(git config --global user.email 2>/dev/null)" ]
}

is_shell_zsh() {
  [ "$SHELL" = "$(which zsh 2>/dev/null)" ]
}

is_lazyvim_installed() {
  [ -d "${HOME}/.config/nvim" ] && [ -f "${HOME}/.config/nvim/init.lua" ]
}

is_dotfiles_symlinked() {
  [ -L "${HOME}/.zshrc" ] && [ -d "${HOME}/dotfiles" ]
}

is_postgres_user_created() {
  if command_exists psql; then
    local os=$(detect_os)
    if [ "$os" = "macos" ]; then
      # On macOS, connect directly without switching user
      psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USER'" 2>/dev/null | grep -q 1
    else
      # On Linux, use postgres user
      run_with_sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USER'" 2>/dev/null | grep -q 1
    fi
  else
    return 1
  fi
}

# Function to show help
show_help() {
  echo "A comprehensive development environment setup script with intelligent caching"
  echo "and performance optimizations for macOS and Ubuntu/Debian systems."
  echo ""
  echo "USAGE:"
  echo "  $0 [OPTIONS]"
  echo ""
  echo "OPTIONS:"
  echo "  --cli-only        Skip GUI applications (useful for LXC containers/servers)"
  echo "  --force           Force reinstallation of all components (ignores cache)"
  echo "  --skip-packages   Skip package installation step (faster config-only runs)"
  echo "  --help, -h        Show this comprehensive help message"
  echo ""
  echo "FEATURES:"
  echo "  Performance Optimized:"
  echo "    • State management system tracks completed installations"
  echo "    • Intelligent caching prevents redundant operations"
  echo "    • ~90% faster on subsequent runs"
  echo "    • Enhanced validation functions for smart skipping"
  echo ""
  echo "  Package Management:"
  echo "    • OS-specific package files (packages-linux.txt, packages-macos.txt)"
  echo "    • Homebrew for macOS, apt/snap for Ubuntu"
  echo "    • Security-restricted custom commands"
  echo "    • Automatic snapd installation when needed"
  echo ""
  echo "  Development Tools:"
  echo "    • mise (runtime version manager)"
  echo "    • lazygit (Git TUI)"
  echo "    • uv (Python package manager)"
  echo "    • JetBrains Mono Nerd Font (with icon support)"
  echo "    • Ruby and Node.js with version selection"
  echo "    • Neovim with LazyVim configuration"
  echo ""
  echo "  System Configuration:"
  echo "    • Zsh shell setup with auto-configuration"
  echo "    • Git global configuration"
  echo "    • PostgreSQL user creation"
  echo "    • Dotfiles symlinking with GNU Stow"
  echo "    • Tmux Plugin Manager (TPM)"
  echo ""
  echo " Security Features:"
  echo "    • Network connectivity validation"
  echo "    • Checksum verification for downloads"
  echo "    • Safe download functions with retries"
  echo "    • Rollback capability on failures"
  echo ""
  echo "STATE MANAGEMENT:"
  echo "  The script maintains installation state in ~/.dotfiles-setup-state"
  echo "  This enables:"
  echo "    • Skipping completed installations automatically"
  echo "    • Version tracking for installed components"
  echo "    • Resuming interrupted installations"
  echo "    • Use --force to override and reinstall everything"
  echo ""
  echo "EXAMPLES:"
  echo "  $0"
  echo "    ➤ Full installation with GUI applications"
  echo ""
  echo "  $0 --cli-only"
  echo "    ➤ Server/container setup (CLI tools only, no GUI apps)"
  echo ""
  echo "  $0 --force"
  echo "    ➤ Force reinstall everything (ignore cached state)"
  echo ""
  echo "  $0 --skip-packages"
  echo "    ➤ Skip package installation, only run configuration steps"
  echo "    ➤ Useful when packages are already installed via other means"
  echo ""
  echo "  $0 --cli-only --skip-packages"
  echo "    ➤ Minimal run: only CLI configurations, no packages or GUI"
  echo ""
  echo "WHAT GETS INSTALLED:"
  echo "  Packages: curl, git, zsh, neovim, tmux, build tools, and more"
  echo "  Fonts: JetBrains Mono Nerd Font (Ubuntu only, macOS via brew)"
  echo "  Tools: mise, lazygit, Ruby, Node.js/NVM, LazyVim"
  echo "  Shell: Zsh with custom configuration and prompt"
  echo "  Dotfiles: Symlinked configuration files for all tools"
  echo "  Database: PostgreSQL user setup"
  echo ""
  echo "PERFORMANCE NOTES:"
  echo "  • First run: Full installation (10-20 minutes depending on system)"
  echo "  • Subsequent runs: Only missing components (~1-2 minutes)"
  echo "  • Use --skip-packages to save 5-10 minutes when packages exist"
  echo "  • State file location: ~/.dotfiles-setup-state"
  echo ""
  echo "SUPPORTED SYSTEMS:"
  echo "  macOS (Intel & Apple Silicon)"
  echo "  Ubuntu/Debian Linux"
  echo "  Other Linux distributions (NOT Tested)"
  echo ""
  echo "For more information, visit: https://github.com/przbadu/dotfiles"
}

# Function to parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --cli-only)
        CLI_ONLY=true
        shift
        ;;
      --force)
        FORCE_REINSTALL=true
        shift
        ;;
      --skip-packages)
        SKIP_PACKAGES=true
        shift
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

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

# Function to check if we need sudo for a command
need_sudo() {
  # If we're already root, no need for sudo
  if [ "$EUID" -eq 0 ]; then
    return 1
  fi

  # Check if sudo is available
  if ! command_exists sudo; then
    error "This script requires sudo privileges for package installation, but sudo is not available"
    error "Please run as root or install sudo"
    return 2
  fi

  return 0
}

# Function to run command with sudo only if needed
run_with_sudo() {
  if need_sudo; then
    local sudo_status=$?
    if [ $sudo_status -eq 2 ]; then
      return 1
    fi
    sudo "$@"
  else
    "$@"
  fi
}

# Function to check network connectivity
check_network() {
  local test_urls=("github.com" "raw.githubusercontent.com" "api.github.com")
  local timeout=5

  log "Checking network connectivity..."

  for url in "${test_urls[@]}"; do
    if curl -s --connect-timeout "$timeout" --max-time "$timeout" "https://$url" >/dev/null 2>&1; then
      log "Network connectivity verified (reached $url)"
      return 0
    fi
  done

  error "Network connectivity check failed"
  error "Unable to reach GitHub servers. Please check your internet connection."
  error "Required domains: ${test_urls[*]}"
  return 1
}

# Function to safely download a file with retries
safe_download() {
  local url="$1"
  local output="$2"
  local max_retries="${3:-3}"
  local timeout="${4:-30}"

  local retry=0
  while [ $retry -lt $max_retries ]; do
    log "Downloading $url (attempt $((retry + 1))/$max_retries)..."

    if curl -fsSL --connect-timeout 10 --max-time "$timeout" "$url" -o "$output"; then
      log "Successfully downloaded: $output"
      return 0
    else
      warn "Download failed (attempt $((retry + 1))/$max_retries)"
      retry=$((retry + 1))
      if [ $retry -lt $max_retries ]; then
        log "Retrying in 3 seconds..."
        sleep 3
      fi
    fi
  done

  error "Failed to download $url after $max_retries attempts"
  return 1
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

# Function to detect system architecture
detect_arch() {
  local arch=$(uname -m)
  case "$arch" in
    x86_64 | amd64)
      echo "x86_64"
      ;;
    aarch64 | arm64)
      echo "arm64"
      ;;
    armv7l)
      echo "armv7"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Function to backup a directory if it exists
backup_dir() {
  local dir=$1
  if dir_exists "$dir"; then
    log "Backing up ${dir} to ${dir}.bak"
    mv "$dir" "${dir}.bak"
    CREATED_BACKUPS+=("$dir")
  fi
}

# Function to add temp directory for cleanup tracking
track_temp_dir() {
  local temp_dir="$1"
  TEMP_DIRECTORIES+=("$temp_dir")
}

# Function to track installed binary for rollback
track_installed_binary() {
  local binary_path="$1"
  INSTALLED_BINARIES+=("$binary_path")
}

# Function to cleanup temporary directories
cleanup_temp_dirs() {
  for temp_dir in "${TEMP_DIRECTORIES[@]}"; do
    if [ -d "$temp_dir" ]; then
      log "Cleaning up temporary directory: $temp_dir"
      rm -rf "$temp_dir"
    fi
  done
  TEMP_DIRECTORIES=()
}

# Function to rollback installations on failure
rollback_installation() {
  error "Installation failed, attempting rollback..."

  # Remove installed binaries
  for binary in "${INSTALLED_BINARIES[@]}"; do
    if [ -f "$binary" ]; then
      log "Removing installed binary: $binary"
      run_with_sudo rm -f "$binary" 2>/dev/null || warn "Could not remove $binary"
    fi
  done

  # Restore backups
  for backup_dir in "${CREATED_BACKUPS[@]}"; do
    if dir_exists "${backup_dir}.bak" && ! dir_exists "$backup_dir"; then
      log "Restoring backup: ${backup_dir}.bak -> $backup_dir"
      mv "${backup_dir}.bak" "$backup_dir"
    fi
  done

  # Cleanup temp directories
  cleanup_temp_dirs

  log "Rollback completed"
}

# Function to handle script exit with cleanup
cleanup_on_exit() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    warn "Script exited with error code $exit_code"
    rollback_installation
  else
    cleanup_temp_dirs
  fi
  exit $exit_code
}

# Set up exit trap for cleanup
trap cleanup_on_exit EXIT INT TERM

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
    if [ "$EUID" -eq 0 ]; then
      echo "chsh -s $(which zsh) $USER"
    else
      echo "sudo chsh -s $(which zsh) $USER"
    fi

    # Prompt user if they want to change shell now
    echo -n "Would you like to change your default shell to zsh now? (y/N) "
    read response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      log "Changing default shell to zsh..."
      run_with_sudo chsh -s "$(which zsh)" "$USER"
    else
      log "Skipping shell change. You can change it later using the command above."
    fi
  fi
}

# Setup mise
setup_mise() {
  if is_completed "MISE"; then
    log "mise installation already completed, skipping..."
    return 0
  fi

  if ! command_exists mise; then
    log "Installing mise..."

    # Create temporary directory for secure installation
    local temp_dir=$(mktemp -d)
    track_temp_dir "$temp_dir"
    cd "$temp_dir"

    # Check network connectivity before downloading
    if ! check_network; then
      return 1
    fi

    # Download mise installation script for inspection
    log "Downloading mise installation script..."
    if safe_download "https://mise.run" "mise-install.sh"; then
      # Basic security check - verify it's a shell script
      if head -1 mise-install.sh | grep -q "^#!/.*sh"; then
        log "Installing mise from downloaded script..."
        chmod +x mise-install.sh
        ./mise-install.sh
      else
        error "Downloaded mise installer does not appear to be a valid shell script"
        return 1
      fi
    else
      error "Failed to download mise installation script"
      return 1
    fi

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

    # Save state on successful installation
    save_state "MISE" "$(mise --version 2>/dev/null || echo 'unknown')"
  else
    warn "mise already installed, skipping..."
    save_state "MISE" "$(mise --version 2>/dev/null || echo 'unknown')"
  fi
}

install_ruby() {
  echo -n "Would you like to install ruby? (y/N) "
  read response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -n "Enter Ruby version (default: 3): "
    read RUBY_VERSION
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

# Install node with nvm (mise install node causes trouble with MCP servers)
install_nodejs() {
  echo -n "Would you like to install Nodejs? (y/N) "
  read response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    log "Installing NVM..."

    # Create temporary directory for secure installation
    local temp_dir=$(mktemp -d)
    track_temp_dir "$temp_dir"
    cd "$temp_dir"

    # Check network connectivity before downloading
    if ! check_network; then
      return 1
    fi

    # Download NVM installation script for inspection
    log "Downloading NVM installation script..."
    local nvm_version="v0.40.3"
    local nvm_url="https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh"

    if safe_download "$nvm_url" "nvm-install.sh"; then
      # Basic security check - verify it's a shell script
      if head -1 nvm-install.sh | grep -q "^#!/.*sh"; then
        log "Installing NVM from downloaded script..."
        chmod +x nvm-install.sh
        ./nvm-install.sh
      else
        error "Downloaded NVM installer does not appear to be a valid shell script"
        return 1
      fi
    else
      error "Failed to download NVM installation script"
      return 1
    fi

    # Load nvm to the current shell
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

    echo -n "Enter Node.js version (default: node): "
    read NODE_VERSION
    NODE_VERSION=${NODE_VERSION:-node}
    log "Installing Node.js ${NODE_VERSION} via NVM..."
    nvm install "$NODE_VERSION"
    nvm use "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"

    # Install yarn globally
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

# Install uv (Python package manager)
install_uv() {
  if is_completed "UV"; then
    log "uv installation already completed, skipping..."
    return 0
  fi

  if ! command_exists uv; then
    log "Installing uv (Python package manager)..."

    # Create temporary directory for secure installation
    local temp_dir=$(mktemp -d)
    track_temp_dir "$temp_dir"
    cd "$temp_dir"

    # Check network connectivity before downloading
    if ! check_network; then
      return 1
    fi

    # Download uv installation script for inspection
    log "Downloading uv installation script..."
    if safe_download "https://astral.sh/uv/install.sh" "uv-install.sh"; then
      # Basic security check - verify it's a shell script
      if head -1 uv-install.sh | grep -q "^#!/.*sh"; then
        log "Installing uv from downloaded script..."
        chmod +x uv-install.sh
        ./uv-install.sh
      else
        error "Downloaded uv installer does not appear to be a valid shell script"
        return 1
      fi
    else
      error "Failed to download uv installation script"
      return 1
    fi

    # Add uv to PATH for current session if installed to ~/.cargo/bin
    if [ -f "${HOME}/.cargo/bin/uv" ]; then
      export PATH="${HOME}/.cargo/bin:$PATH"
    fi

    # Verify uv is now available
    if ! command_exists uv; then
      error "uv installation failed or not in PATH. Please check installation and try again."
      return 1
    fi

    # Save state on successful installation
    save_state "UV" "$(uv --version 2>/dev/null || echo 'unknown')"
  else
    warn "uv already installed, skipping..."
    save_state "UV" "$(uv --version 2>/dev/null || echo 'unknown')"
  fi
}

# Configure git
configure_git() {
  if is_completed "GIT_CONFIG"; then
    log "Git configuration already completed, skipping..."
    return 0
  fi

  log "Checking git configuration..."
  if ! is_git_configured; then
    echo -n "Enter your git username: "
    read GIT_USERNAME
    echo -n "Enter your git email: "
    read GIT_EMAIL
    git config --global color.ui true
    git config --global user.name "${GIT_USERNAME}"
    git config --global user.email "${GIT_EMAIL}"
    save_state "GIT_CONFIG" "${GIT_USERNAME}:${GIT_EMAIL}"
  else
    warn "Git already configured, skipping..."
    save_state "GIT_CONFIG" "$(git config --global user.name):$(git config --global user.email)"
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

  # Create temporary directory for downloads
  local temp_dir=$(mktemp -d)
  track_temp_dir "$temp_dir"
  cd "$temp_dir"

  # Check network connectivity before downloading
  if ! check_network; then
    return 1
  fi

  # Download and extract templates
  log "Downloading Neovim templates..."
  if git clone https://github.com/przbadu/dotfiles.git; then
    # Copy config files
    log "Copying config files..."
    cp -r dotfiles/templates/nvim/lua/config/*.* "${HOME}/.config/nvim/lua/config/" 2>/dev/null || warn "No config files found to copy"

    # Copy plugin files
    log "Copying plugin files..."
    cp -r dotfiles/templates/nvim/lua/plugins/*.* "${HOME}/.config/nvim/lua/plugins/" 2>/dev/null || warn "No plugin files found to copy"

    log "Custom Neovim configuration setup completed."
  else
    error "Failed to download Neovim templates from GitHub"
  fi

  # Cleanup temp directory
  rm -rf "$temp_dir"
}

# Install LazyVim configuration
install_lazyvim() {
  log "Checking LazyVim installation..."
  if ! dir_exists "${HOME}/.config/nvim"; then
    log "Fresh install LazyVim..."
    rm -rf "${HOME}/.config/nvim"
    rm -rf "${HOME}/.local/share/nvim"
    rm -rf "${HOME}/.local/state/nvim"
    rm -rf "${HOME}/.cache/nvim"

    git clone https://github.com/LazyVim/starter "${HOME}/.config/nvim"
    rm -rf "${HOME}/.config/nvim/.git"

    # Add custom config setup here
    setup_custom_neovim_config
  else
    warn "LazyVim configuration already exists, skipping..."
  fi
}

# Function to verify file checksum
verify_checksum() {
  local file="$1"
  local expected_checksum="$2"
  local algorithm="${3:-sha256}"

  if ! command_exists "${algorithm}sum"; then
    warn "Cannot verify checksum: ${algorithm}sum not available"
    return 1
  fi

  local actual_checksum=$(${algorithm}sum "$file" | cut -d' ' -f1)
  if [ "$actual_checksum" = "$expected_checksum" ]; then
    log "Checksum verification passed for $file"
    return 0
  else
    error "Checksum verification failed for $file"
    error "Expected: $expected_checksum"
    error "Actual: $actual_checksum"
    return 1
  fi
}

# Install lazygit (Ubuntu only - macOS uses brew)
install_lazygit() {
  if is_completed "LAZYGIT"; then
    log "lazygit installation already completed, skipping..."
    return 0
  fi

  log "Checking lazygit installation..."
  if ! command_exists lazygit; then
    local os=$(detect_os)
    if [ "$os" = "ubuntu" ]; then
      log "Installing lazygit for Ubuntu..."
      local arch=$(detect_arch)

      # Map architecture to lazygit naming convention
      local lazygit_arch
      case "$arch" in
        x86_64)
          lazygit_arch="Linux_x86_64"
          ;;
        arm64)
          lazygit_arch="Linux_arm64"
          ;;
        armv7)
          lazygit_arch="Linux_armv6"
          ;;
        *)
          error "Unsupported architecture: $arch"
          return 1
          ;;
      esac

      # Check network connectivity before downloading
      if ! check_network; then
        return 1
      fi

      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')

      # Download lazygit binary
      local lazygit_url="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_${lazygit_arch}.tar.gz"
      local checksum_url="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/checksums.txt"

      log "Downloading lazygit v${LAZYGIT_VERSION} for ${lazygit_arch}..."
      if ! safe_download "$lazygit_url" "lazygit.tar.gz"; then
        return 1
      fi

      # Download and verify checksum
      log "Downloading checksums for verification..."
      if safe_download "$checksum_url" "checksums.txt"; then
        local expected_checksum=$(grep "lazygit_${LAZYGIT_VERSION}_${lazygit_arch}.tar.gz" checksums.txt | cut -d' ' -f1)
        if [ -n "$expected_checksum" ]; then
          if verify_checksum "lazygit.tar.gz" "$expected_checksum"; then
            log "Checksum verified, proceeding with installation..."
            tar xf lazygit.tar.gz lazygit
            run_with_sudo install lazygit -D -t /usr/local/bin/
            track_installed_binary "/usr/local/bin/lazygit"
            log "lazygit installed successfully"
          else
            error "Checksum verification failed, aborting installation"
            rm -f lazygit.tar.gz checksums.txt
            return 1
          fi
        else
          warn "Could not find checksum for lazygit binary, proceeding without verification"
          tar xf lazygit.tar.gz lazygit
          sudo install lazygit -D -t /usr/local/bin/
          track_installed_binary "/usr/local/bin/lazygit"
        fi
      else
        warn "Could not download checksums, proceeding without verification"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit -D -t /usr/local/bin/
        track_installed_binary "/usr/local/bin/lazygit"
      fi

      # Cleanup
      rm -f lazygit.tar.gz lazygit checksums.txt
    else
      log "lazygit should be installed via package manager on macOS"
    fi

    # Save state on successful installation or if already present
    save_state "LAZYGIT" "$(lazygit --version 2>/dev/null | head -1 || echo 'unknown')"
  else
    warn "lazygit already installed, skipping..."
    save_state "LAZYGIT" "$(lazygit --version 2>/dev/null | head -1 || echo 'unknown')"
  fi
}

# Install JetBrains Mono Nerd Font
install_nerd_fonts() {
  if is_completed "NERD_FONTS"; then
    log "JetBrains Mono Nerd Font installation already completed, skipping..."
    return 0
  fi

  log "Checking JetBrains Mono Nerd Font installation..."

  local os=$(detect_os)
  if [ "$os" = "ubuntu" ]; then
    log "Installing JetBrains Mono Nerd Font for Ubuntu..."

    # Check if fonts directory exists, if not create it
    local fonts_dir="/usr/local/share/fonts"
    if [ ! -d "$fonts_dir" ]; then
      log "Creating fonts directory: $fonts_dir"
      run_with_sudo mkdir -p "$fonts_dir"
    fi

    # Check if JetBrains Mono Nerd Font is already installed
    if fc-list | grep -qi "jetbrainsmono.*nerd"; then
      warn "JetBrains Mono Nerd Font already installed, skipping..."
      return 0
    fi

    # Create temporary directory for downloads
    local temp_dir=$(mktemp -d)
    track_temp_dir "$temp_dir"
    cd "$temp_dir"

    # Check network connectivity before downloading
    if ! check_network; then
      return 1
    fi

    # Download JetBrains Mono Nerd Font
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    log "Downloading JetBrains Mono Nerd Font..."
    if safe_download "$font_url" "JetBrainsMono.zip"; then
      log "Extracting fonts to $fonts_dir..."
      run_with_sudo unzip -o "JetBrainsMono.zip" -d "$fonts_dir"

      # Update font cache
      log "Updating font cache..."
      run_with_sudo fc-cache -fv

      log "JetBrains Mono Nerd Font installed successfully"
      save_state "NERD_FONTS" "latest"
    else
      error "Failed to download JetBrains Mono Nerd Font"
      return 1
    fi
  else
    log "JetBrains Mono Nerd Font should be installed via package manager on macOS"
    save_state "NERD_FONTS" "system"
  fi
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

    # Check if it's a warning message
    if [[ "$line" =~ ^warn ]]; then
      local warning_msg=$(echo "$line" | sed 's/^warn *//')
      warn "$warning_msg"
      # Check if it's a cask package (GUI)
    elif [[ "$line" =~ ^cask: ]]; then
      if [ "$CLI_ONLY" = true ]; then
        log "Skipping GUI app (--cli-only): $line"
        continue
      fi
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
  run_with_sudo apt update

  # Install snapd if not present and not CLI-only mode
  if ! command_exists snap && [ "$CLI_ONLY" = false ]; then
    log "Installing snapd..."
    run_with_sudo apt install -y snapd
  fi

  # Read packages from file and install
  while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
      continue
    fi

    # Check if it's a warning message
    if [[ "$line" =~ ^warn ]]; then
      local warning_msg=$(echo "$line" | sed 's/^warn *//')
      warn "$warning_msg"
      # Check if it's a safe custom command (only allow specific package managers)
    elif [[ "$line" =~ ^(sudo apt |snap install |apt install ).* ]]; then
      # Skip snap commands in CLI-only mode
      if [[ "$line" =~ snap ]] && [ "$CLI_ONLY" = true ]; then
        log "Skipping GUI app command (--cli-only): $line"
        continue
      fi
      log "Executing package command: $line"
      # Replace sudo with run_with_sudo in the command
      local safe_command=$(echo "$line" | sed 's/^sudo //')
      if [[ "$line" =~ ^sudo ]]; then
        eval "run_with_sudo $safe_command" || warn "Failed to execute package command: $line"
      else
        eval "$line" || warn "Failed to execute package command: $line"
      fi
      # Check if it's a snap package
    elif [[ "$line" =~ ^snap: ]]; then
      if [ "$CLI_ONLY" = true ]; then
        log "Skipping GUI app (--cli-only): $line"
        continue
      fi
      package_line=$(echo "$line" | sed 's/^snap: *//')
      # Parse package name and flags (e.g., "obsidian --classic" -> package="obsidian", flags="--classic")
      package=$(echo "$package_line" | awk '{print $1}')
      flags=$(echo "$package_line" | cut -d' ' -f2-)

      # If package and flags are the same, there are no flags
      if [ "$package" = "$flags" ]; then
        flags=""
      fi

      if [ -n "$flags" ]; then
        log "Installing snap package: $package with flags: $flags"
        run_with_sudo snap install $package $flags || warn "Failed to install snap package: $package $flags"
      else
        log "Installing snap package: $package"
        run_with_sudo snap install $package || warn "Failed to install snap package: $package"
      fi
    else
      log "Installing apt package: $line"
      run_with_sudo apt install -y "$line" || warn "Failed to install apt package: $line"
    fi
  done <"$packages_file"
}

# setup database
setup_database() {
  if is_completed "POSTGRES_SETUP"; then
    log "PostgreSQL setup already completed, skipping..."
    return 0
  fi

  if ! command_exists psql; then
    error "PostgreSQL is not installed. Please install it first."
    error "On Ubuntu/Debian: sudo apt install postgresql libpq-dev"
    error "On macOS: brew install postgresql"
    return 1
  fi

  log "Setting up postgresql root user"
  if is_postgres_user_created; then
    log "PostgreSQL user '$USER' already exists, skipping user creation"
  else
    log "Creating PostgreSQL user '$USER'"
    local os=$(detect_os)
    if [ "$os" = "macos" ]; then
      # On macOS, create user directly
      createuser $USER -s 2>/dev/null || psql postgres -c "CREATE USER $USER WITH SUPERUSER;" 2>/dev/null
    else
      # On Linux, use postgres user
      run_with_sudo -u postgres createuser $USER -s
    fi
  fi

  save_state "POSTGRES_SETUP" "$USER"
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

    # Check network connectivity before cloning
    if ! check_network; then
      return 1
    fi

    log "Cloning dotfiles to ~/dotfiles"
    if ! git clone git@github.com:przbadu/dotfiles.git ~/dotfiles; then
      warn "SSH clone failed, trying HTTPS..."
      if ! git clone https://github.com/przbadu/dotfiles.git ~/dotfiles; then
        error "Failed to clone dotfiles repository. Please check your internet connection and try again."
        return 1
      fi
    fi
    cd "$HOME/dotfiles"
  fi

  # Stow all dotfiles from the current directory
  log "Symlinking dotfiles"
  stow --adopt --ignore=setup.sh --ignore=packages-linux.txt --ignore=packages-macos.txt --ignore=todo.txt --ignore=README.md .

  if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
    log "Install tmux package manager inside ~/.tmux/plugins/tpm"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
}

# Check system privileges and requirements
check_system_requirements() {
  log "Checking system requirements..."

  # Check if we're running on a supported system
  local os=$(detect_os)
  if [ "$os" = "unknown" ]; then
    error "Unsupported operating system. This script supports macOS and Ubuntu/Debian only."
    return 1
  fi

  # Warn about privilege requirements for package installation
  if [ "$os" = "ubuntu" ] && need_sudo; then
    local sudo_status=$?
    if [ $sudo_status -eq 2 ]; then
      return 1
    fi
    log "This script will require sudo privileges for package installation"
    log "You may be prompted for your password during the installation process"
  elif [ "$os" = "ubuntu" ] && [ "$EUID" -eq 0 ]; then
    log "Running as root - sudo will not be used for package installation"
  fi

  log "System requirements check passed"
  return 0
}

install_custom_packages() {
  if [ "$os" = "ubuntu" ] && need_sudo; then
    if ! command_exists heroku; then
      log "Installing heroku cli"
      curl https://cli-assets.heroku.com/install.sh | sh
    fi

    log "Install stripe"
    if ! command_exists stripe; then
      curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor | sudo tee /usr/share/keyrings/stripe.gpg
      echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" | sudo tee -a /etc/apt/sources.list.d/stripe.list
      sudo apt update
      sudo apt install stripe
    fi
  fi
}

# Main installation process
main() {
  # Parse command line arguments
  parse_args "$@"

  if [ "$CLI_ONLY" = true ]; then
    log "Starting CLI-only installation process..."
  else
    log "Starting full installation process..."
  fi

  # Check system requirements first
  if ! check_system_requirements; then
    error "System requirements check failed. Exiting."
    exit 1
  fi

  # Install packages from packages.txt first
  if [ "$SKIP_PACKAGES" = true ]; then
    log "Skipping package installation (--skip-packages flag)"
  else
    install_packages
  fi

  # Install JetBrains Mono Nerd Font
  install_nerd_fonts

  # Configure zsh as default shell (zsh installed via package manager)
  install_and_select_zsh

  # Install OS-specific packages
  install_lazygit
  setup_mise
  install_languages
  install_uv
  configure_git
  install_neovim
  install_lazyvim
  copy_dotfiles
  setup_database
  install_custom_packages

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
main "$@"
