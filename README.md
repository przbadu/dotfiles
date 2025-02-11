# LXC Container Development Environment Setup

This script automates the setup of a development environment in an LXC container, installing and configuring essential development tools and utilities.

## Features

- System dependencies installation
- Development tools setup:
  - mise (version manager)
  - Ruby
  - Node.js
  - Git
  - Neovim
  - LazyVim
  - Lazygit
- Idempotent installation (safe to run multiple times)
- Automatic backup of existing configurations
- Detailed logging and error handling

## Prerequisites

- Ubuntu/Debian-based LXC container
- Internet connection
- Sudo privileges


## Installation

### IMPORTANT: Security Note

We encourage users to inspect the script before running it:

> NOTE: because this script contains step to install zsh and change your default shell, running script
> Directly from curl command e.g: `curl -sSL <path> | bash` will throw error.
> if you already have zsh installed, you can run it like that, otherwise follow:

```bash
curl -sSL https://raw.githubusercontent.com/przbadu/dotfiles/main/setup.sh > setup.sh
# Review the content please...
cat setup.sh
chmod +x setup.sh
./setup.sh

# after succesfully completed
rm setup.sh
```

### Configuration Options

During installation, you'll be prompted to configure:

- Git username and email (if not already configured)
- Ruby version (default: 3)
- Node.js version (default: 22.13.0)

## What Gets Installed

### System Dependencies

- build-essential
- rustc
- libssl-dev
- libyaml-dev
- zlib1g-dev
- libgmp-dev

### Development Tools

- mise (version manager)
- Ruby (configurable version)
- Node.js (configurable version)
- Git (with user configuration)
- Neovim (latest version)
- LazyVim (with dependencies)
    - git
    - fzf
    - curl
    - ripgrep
- Lazygit (latest version)

## Directory Structure

The script creates and modifies the following directories:

Copy

```sh
$HOME/
├── .local/
│   ├── bin/
│   ├── share/nvim/
│   └── state/nvim/
├── .config/
│   └── nvim/
└── .cache/
    └── nvim/
```

## Backup Behavior

The script automatically backs up existing configurations by appending `.bak` to the directory names:

- `~/.config/nvim` → `~/.config/nvim.bak`
- `~/.local/share/nvim` → `~/.local/share/nvim.bak`
- `~/.local/state/nvim` → `~/.local/state/nvim.bak`
- `~/.cache/nvim` → `~/.cache/nvim.bak`

## Troubleshooting

### Common Issues

1. **Permission Denied**
    
```sh
sudo chmod +x setup-container.sh
```
    
2. **Network Issues**
    - Ensure your container has internet access
    - Check if required URLs are accessible

3. **Installation Failures**
    - Check the logs for specific error messages
    - Ensure you have sufficient disk space
    - Verify system requirements are met

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