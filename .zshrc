# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

### Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

### Zinit snippets
zinit snippet OMZP::git # OMZP (to use oh-my-zsh plugins)
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

### Keybindings
# ctrl+f/b -> move forward/backward
# ctrl+p/n -> previous/next suggestions (cycle through)
# ctrl+a/e -> jump to start/end of the line
bindkey -e # emacs keybindings to use ctrl+n/p/a

# Filter through line or search result from history
bindkey '^p' up-line-or-search
bindkey '^n' down-line-or-search
bindkey '^[[A' up-line-or-search                                                
bindkey '^[[B' down-line-or-search

### Other configs
# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Macos
if [[ $(uname) == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export PGGSSENCMODE="disable"
else
  # Shell integrations
  # eval "$(fzf --zsh)"
  eval "$(zoxide init --cmd cd zsh)"
fi

# Activate mise
eval "$(~/.local/bin/mise activate)"

# Load completions
autoload -U compinit && compinit
zinit cdreplay -q

### Alias
alias ls='ls --color'
alias e='nvim'
alias rc="rails c"
alias rs="rails s"
alias sk="bundle exec sidekiq -c 1 -v"
alias es7="docker start elesticsearch_7 || docker run -d --name elesticsearch_7 -p 9200:9200 -e \"http.host=0.0.0.0\" -e \"transport.host=127.0.0.1\" docker.elastic.co/elasticsearch/elasticsearch:7.10.1"
alias redis="docker start redis || docker run -d --name redis -p 6379:6379 redis"
alias po="cd ~/projects/pex/po-app"
alias bcc="npx better-commits"
alias top='btop'
alias htop='btop'
alias dcdev="docker-compose -f docker-compose-dev.yml"
alias web="dcdev run web"
alias rtest="RAILS_ENV=test bundle exec rake test TESTOPTS=\"--seed=25773\" TESTOPTS=--profile"

### PATH configurations
export EDITOR="nvim"
export SUDO_EDITOR="nvim"

# nvm (node version manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# nvim path
export PATH="/opt/nvim-linux-x86_64/bin:$PATH"
# LMStudio
export PATH="$PATH:/home/przbadu/.lmstudio/bin"
# .local/bin - custom bin executable path
export PATH="${HOME}/.local/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
