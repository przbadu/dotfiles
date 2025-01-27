# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)


# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# method to detect Linux/Mac os
is_linux() {
    case "$(uname -s)" in
        Linux*) return 0 ;;
        *) return 1 ;;
    esac
}

is_mac() {
    case "$(uname -s)" in
        Darwin*) return 0 ;;
        *) return 1 ;;
    esac
}

export EDITOR="nvim"
export SUDO_EDITOR="nvim"

alias cl="clear"
alias python="python3"
alias rubymine="open -na \"RubyMine.app\""
alias tn="tmux new"
alias rc="rails c"
alias rs="rails s"
alias js="bundle exec jekyll serve"
alias jb="bundle exec jekyll build"
alias sk="bundle exec sidekiq -c 1 -v"
alias es7="docker start elesticsearch_7 || docker run -d --name elesticsearch_7 -p 9200:9200 -e \"http.host=0.0.0.0\" -e \"transport.host=127.0.0.1\" docker.elastic.co/elasticsearch/elasticsearch:7.10.1"
alias redis="docker start redis || docker run -d --name redis -p 6379:6379 redis"
alias e='nvim'
alias po="cd ~/projects/pex/po-app"
alias blog='cd ~/projects/personal/przbadu.github.io'
alias expense='cd ~/projects/personal/MyExpenses'
alias gcc="npx better-commits"
alias tmuxworkflow="sh ~/workflows/tmux-workflow.sh"
alias top='btop'
alias htop='btop'
alias dcdev="docker-compose -f docker-compose-dev.yml"
alias web="dcdev run web"
alias rtest="RAILS_ENV=test bundle exec rake test TESTOPTS=\"--seed=25773\" TESTOPTS=--profile"
# alias rtest="bundle exec ruby -I test "
alias ibrew="arch -x86_64 $HOMEBREW_PREFIX/bin/brew"
alias dashy="docker run -d -p 8080:80 --name przbadu --restart=always lissy93/dashy:latest"
alias ridesharedb="psql \"postgres://owner:@localhost:5432/rideshare_development\""

if is_mac; then
  alias alacritty="/Applications/Alacritty.app/Contents/MacOS/alacritty"
fi

# Obsidian aliases
alias oo='cd $HOME/SecondBrain'
alias or='$EDITOR $HOME/SecondBrain/inbox/*.md'
alias ou='cd $HOME/SecondBrain && node batchUpload.js --lastmod-days-window 5'

# Open AI api key
export OPENAI_API_KEY="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"

# flutter
if [[ -d "$HOME/flutter/bin" ]]
then
  export PATH="$HOME/flutter/bin:$PATH"
else
  export PATH="$HOME/development/flutter/bin:$PATH"
fi

# GO
export PATH=$PATH:/usr/local/go/bin
# DENO
export DENO_INSTALL="~/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Register ~/.local/bin to the PATH
export PATH=~/.local/bin:$PATH
# Android cmdline-tools
export ANDROID_HOME=~/Android
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH

# home brew
if [ -d "$HOMEBREW_PREFIX/bin/brew" ]; then
  eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
  export PATH="$HOMEBREW_PREFIX/opt/postgresql@16/bin:$PATH"
  # export PATH="$HOMEBREW_PREFIX/opt/postgresql@14/bin:$PATH"
fi

# sources
source $ZSH/oh-my-zsh.sh
source "$HOME/.cargo/env"
# source $HOME/.asdf/asdf.sh

# Fix Ctrl + arrow functionality for iTerm2
# bindkey -e
# bindkey '\e\e[C' forward-word
# bindkey '\e\e[D' backward-word
# Alt + arrow
# bindkey '^[[1;9C' forward-word
# bindkey '^[[1;9D' backward-word
# Fix backward and forward jumping
# If these characters are different find by running Cmd + v followed by the key Control + Backward arrow / Forward arrow
# bindkey '^[[1;3D' backward-word
# bindkey '^[[1;3C' forward-word

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# alias ls="colorls"

# bun completions
[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export GITHUB_ACCESS_TOKEN="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"

# fly
export FLYCTL_INSTALL="/home/przbadu/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

## FIX: Rails and Puma crash issue with PG
if is_mac; then
  export PGGSSENCMODE="disable"
fi

# ASDF in Mac
if is_mac; then
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
fi


###############################
# OMAKUB configs
# #############################
if is_linux; then
  export OMAKUB_PATH="/home/$USER/.local/share/omakub"
  export PATH="$HOME/.local/share/omakub/bin:$PATH"
  set +h

  # Setup mise
  if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
  else
    gum confirm "You're missing mise (replacement for rbenv + nodenv). Install now?" && \
      source $OMAKUB_PATH/install/mise.sh
  fi

  eval "$(zoxide init bash)"
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/przbadu/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/przbadu/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/przbadu/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/przbadu/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


### Coder config
# Listen on port 80
export CODER_HTTP_ADDRESS=0.0.0.0:8080
# Enable TLS and listen on port 443)
export CODER_TLS_ENABLE=false
## Redirect from HTTP to HTTPS
export CODER_REDIRECT_TO_ACCESS_URL=false

# Added by Windsurf
export PATH="/Users/przbadu/.codeium/windsurf/bin:$PATH"
