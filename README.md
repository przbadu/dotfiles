# Dotfiles Repository

This repository contains dotfiles and setup scripts for automated development environment configuration. It includes system packages, development tools setup, and symlink management using GNU Stow.

## Features

- Automated setup script for development environment
- Package lists for Linux (Ubuntu/Debian) and macOS
- GNU Stow-based dotfiles management
- Development tools installation:
  - mise (version manager)
  - Ruby, Node.js
  - Git configuration
  - Neovim with LazyVim
  - Lazygit
- Idempotent installation (safe to run multiple times)
- Automatic backup of existing configurations

## Prerequisites

- Linux (Ubuntu/Debian) or macOS
- Internet connection
- Sudo privileges for package installation (or run as root on Linux)


## Installation

### Option 1: Direct Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/przbadu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the setup script
./setup.sh
```

### Option 2: Remote Installation

**IMPORTANT: Security Note**
We encourage users to inspect the script before running it.

> NOTE: Because this script installs zsh and changes your default shell, running the script
> directly from curl (e.g: `curl -sSL <path> | bash`) may cause errors.
> If you already have zsh installed, you can run it directly, otherwise follow the manual approach:

**Manual approach (if you want to use zsh shell):**

```bash
curl -sSL https://raw.githubusercontent.com/przbadu/dotfiles/main/setup.sh > setup.sh
# Review the content please...
chmod +x setup.sh
./setup.sh

# Clean up after successful completion
rm setup.sh
```

**Direct approach (if you already have zsh or want to use bash):**

```bash
curl -sSL https://raw.githubusercontent.com/przbadu/dotfiles/main/setup.sh | bash
```

### Option 3: Manual Package Installation

You can also install packages manually using the provided package lists:

```bash
# For Linux (Ubuntu/Debian)
sudo apt update && sudo apt install $(cat packages-linux.txt)

# For macOS (using Homebrew)
brew install $(cat packages-macos.txt)
```

### Configuration Options

During installation, you'll be prompted to configure:

- Git username and email (if not already configured)
- Ruby version (default: 3)
- Node.js version (default: 22.13.0)

### Running with Different Privileges

The script automatically detects your privilege level and uses sudo only when necessary:

- **Regular user**: Script will use `sudo` for package installations
- **Root user**: Script runs directly without `sudo` (Linux only)
- **No sudo available**: Script will show clear error messages

```bash
# As regular user (recommended)
./setup.sh

# As root user (Linux containers/servers)
sudo ./setup.sh
```

## What Gets Installed

### System Packages

**Linux (packages-linux.txt):**
- Essential build tools (build-essential, rustc)
- Development libraries (libssl-dev, libyaml-dev, zlib1g-dev, libgmp-dev)
- System utilities and tools

**macOS (packages-macos.txt):**
- Development tools and utilities via Homebrew
- Compatible macOS equivalents of Linux packages

### Development Tools

- **mise** - Universal version manager for programming languages
- **Ruby** (configurable version, default: 3)
- **Node.js** (configurable version, default: 22.13.0)
- **Git** with user configuration
- **Neovim** (latest version) with LazyVim configuration
- **LazyVim** dependencies:
  - git, fzf, curl, ripgrep
- **Lazygit** (latest version)
- **GNU Stow** for dotfiles management

## Repository Structure

```
dotfiles/
├── README.md              # This file
├── setup.sh              # Main setup script
├── packages-linux.txt    # Linux package list
├── packages-macos.txt    # macOS package list
└── [dotfiles]/           # Dotfiles managed by GNU Stow
```

## Directory Structure (After Installation)

The script creates and modifies the following directories:

```sh
$HOME/
├── .local/
│   ├── bin/              # Local binaries
│   ├── share/nvim/       # Neovim shared data
│   └── state/nvim/       # Neovim state files
├── .config/
│   └── nvim/             # Neovim configuration
├── .cache/
│   └── nvim/             # Neovim cache
└── .dotfiles/            # This repository (if cloned locally)
```

## Backup Behavior

The script automatically backs up existing configurations by appending `.bak` to the directory names:

- `~/.config/nvim` → `~/.config/nvim.bak`
- `~/.local/share/nvim` → `~/.local/share/nvim.bak`
- `~/.local/state/nvim` → `~/.local/state/nvim.bak`
- `~/.cache/nvim` → `~/.cache/nvim.bak`

## Dotfiles Management

This repository uses GNU Stow for managing dotfiles. After installation, you can:

```bash
# Navigate to dotfiles directory
cd ~/.dotfiles

# Use stow to symlink dotfiles (example)
stow nvim    # Links nvim config to ~/.config/nvim
stow git     # Links git config to ~/.gitconfig
stow zsh     # Links zsh config to ~/.zshrc
```

## Testing

Before running the full installation, especially after making changes to the script, it's recommended to test it thoroughly:

### Quick Testing Strategy

**1. Syntax Check First:**
```bash
bash -n setup.sh
```

**2. Test Individual Functions:**
```bash
# Test network connectivity
bash -c 'source setup.sh; check_network'

# Test OS and architecture detection
bash -c 'source setup.sh; echo "OS: $(detect_os)"; echo "Arch: $(detect_arch)"'

# Test sudo handling
bash -c 'source setup.sh; need_sudo && echo "Needs sudo" || echo "No sudo needed"'

# Test system requirements check
bash -c 'source setup.sh; check_system_requirements'
```

**3. Safe Testing Environments:**

**Option A: Disposable Environment (Recommended)**
- Docker container
- Virtual machine  
- Fresh Ubuntu/macOS install

**Option B: Limited Testing**
```bash
# Test with package installation commented out
# Edit setup.sh temporarily to comment out destructive operations
```

### What to Test Specifically

1. **Privilege detection** - Run as different users (regular user, root)
2. **Network checks** - Test with/without internet connection
3. **Architecture detection** - Verify correct architecture detection on your system
4. **Error handling** - Interrupt script (Ctrl+C) to test rollback mechanisms
5. **Package file parsing** - Verify warning messages and package commands work correctly
6. **Cross-platform compatibility** - Test on both macOS and Linux if possible

### Testing Checklist

- [ ] Syntax validation passes
- [ ] Functions work individually
- [ ] Network connectivity check works
- [ ] OS/architecture detection correct
- [ ] Sudo handling works for your user level
- [ ] System requirements check passes
- [ ] Rollback mechanism works (test by interrupting)
- [ ] Package files parse correctly
- [ ] Full installation in disposable environment

## Troubleshooting

### Common Issues

1. **Permission Denied**
    
```bash
chmod +x setup.sh
```
    
2. **Network Issues**
    - Ensure your system has internet access
    - Check if required URLs are accessible

3. **Installation Failures**
    - Check the logs for specific error messages
    - Ensure you have sufficient disk space
    - Verify system requirements are met

4. **Stow Conflicts**
    - Remove existing dotfiles or backup them before running stow
    - Use `stow -D <package>` to unlink before re-linking

5. **Sudo Issues**
    - Script automatically detects privilege level
    - Run as regular user (recommended) or as root
    - Ensure sudo is available if not running as root

## Contributing

4. Fork the repository
5. Create your feature branch
6. Commit your changes
7. Push to the branch
8. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [LazyVim](https://github.com/LazyVim/starter)
- [Lazygit](https://github.com/jesseduffield/lazygit)
- [mise](https://mise.run)
