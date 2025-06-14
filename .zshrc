# Add deno completions to search path
if [[ ":$FPATH:" != *":/Users/finxol/.zsh/completions:"* ]]; then export FPATH="/Users/finxol/.zsh/completions:$FPATH"; fi
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="gallifrey"

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
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

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




alias ll="eza -la --icons --group-directories-first --git"

export PATH="/opt/homebrew/opt/node@20/bin:$PATH"


###############
# SSH Aliases #
###############

# Connect to VM
alias ssh-vm="ssh 'finxol@fdfa:6c9d:d516:7dda:78b0:39ff:fe3d:e285'"

# Connect to DigitalOcean droplet
alias dopers="ssh finxol@157.230.116.140"

# Connect to local Raspberry Pi
raspi() {
    ip=`curl -s https://am.i.mullvad.net/ip`

    if [ "$ip" = "82.67.127.125" ]; then
        ssh finxol@192.168.1.158
    else
        echo "Not connected to home network"
        echo "Please connect to Wireguard VPN"
    fi
}

###############

# bun completions
[ -s "/Users/finxol/.bun/_bun" ] && source "/Users/finxol/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Deno global packages
export PATH="$PATH:$HOME/.deno/bin"

export EDITOR="vim"

alias c="clear -x"
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/finxol/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bit
case ":$PATH:" in
  *":/Users/finxol/bin:"*) ;;
  *) export PATH="$PATH:/Users/finxol/bin" ;;
esac
# bit end


eval "$(zoxide init zsh)"

# Automatically attach to or create tmux session named 'default'
# only when running inside Ghostty and not already in tmux.
if [[ -z "$TMUX" && "$TERM_PROGRAM" = "ghostty" ]]; then
  exec tmux new -A -s default
fi

# Deploy Jester's stock website
deploy-stock() {
	dopers "pm2 stop stock-stats && rm -rf /srv/http/stock-stats/*" && rsync -av --exclude=node_modules -e "ssh -i ~/.ssh/id_rsa" ~/Projects/dev/web/stock-stats/* finxol@157.230.116.140:/srv/http/stock-stats && dopers "cd /srv/http/stock-stats && ~/.bun/bin/bun install && ~/.bun/bin/bun run build && NODE_ENVIRONMENT=production pm2 start .output/server/index.mjs --name stock-stats"
}

# Unquarantine app
fix-app() {
	xattr -d com.apple.quarantine $1
}
. "/Users/finxol/.deno/env"
# Initialize zsh completions (added by deno install script)
autoload -Uz compinit
compinit