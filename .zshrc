# uncomment to profile prompt startup with zprof
# zmodload zsh/zprof

# history
SAVEHIST=100000

# vim bindings
bindkey -v


# fpath=( "$HOME/.zfunctions" $fpath )

# ! MAKE SURE ARM64 Brew is used
# which brew                                                                                                                                                          <aws:blpsaml>
# /opt/homebrew/bin/brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# ! NOT USING ANTIGEN
# antigen time!
# source /usr/local/share/antigen/antigen.zsh


######################################################################
### install some antigen bundles

# local b="antigen bundle"


# Don't load the oh-my-zsh's library. Takes too long. No need.
# antigen use oh-my-zsh

# Guess what to install when running an unknown command.
# antigen bundle command-not-found

# Helper for extracting different types of archives.
# antigen bundle extract

# homebrew  - autocomplete on `brew install`
# antigen bundle brew
# antigen bundle brew-cask

# history search
# antigen bundle zsh-users/zsh-history-substring-search ./zsh-history-substring-search.zsh

# colors for all files! # ! HAS ISSUES!! - not needed
# antigen bundle trapd00r/zsh-syntax-highlighting-filetypes

# dont set a theme, because pure does it all
# antigen bundle mafredri/zsh-async
# antigen bundle sindresorhus/pure

# Tell antigen that you're done.
# antigen apply

###
#################################################################################################


# ! not needed
# bind UP and DOWN arrow keys for history search
# zmodload zsh/terminfo
# bindkey "$terminfo[kcuu1]" history-substring-search-up
# bindkey "$terminfo[kcud1]" history-substring-search-down

export PURE_GIT_UNTRACKED_DIRTY=0

# Automatically list directory contents on `cd`.
auto-ls () {
	emulate -L zsh;
	# explicit sexy ls'ing as aliases arent honored in here.
	hash gls >/dev/null 2>&1 && CLICOLOR_FORCE=1 gls -aFh --color --group-directories-first || ls
}
chpwd_functions=( auto-ls $chpwd_functions )


# Enable autosuggestions automatically
# zle-line-init() {
#     zle autosuggest-start
# }

# zle -N zle-line-init


# history mgmt
# http://www.refining-linux.org/archives/49/ZSH-Gem-15-Shared-history/
setopt inc_append_history
setopt share_history


zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'


# uncomment to finish profiling
# zprof

# installed with homebrew
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
export PATH="/usr/local/sbin:$PATH"

# python3 unversioned symlinks
export PATH=/opt/homebrew/opt/python@3.12/libexec/bin:$PATH

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# oh-my-zsh

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

ZSH_THEME="strug"
# ZSH_THEME="lukap2211"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  macos
  gh
  git
  aws
  azure
  docker
  docker-compose
  zsh-interactive-cd
  zsh-navigation-tools
)

source $ZSH/oh-my-zsh.sh

# Load default dotfiles
source ~/.bash_profile

# ! alternative simple prompt
# # PURE Prompt
# autoload -U promptinit; promptinit

# # optionally define some options
# PURE_CMD_MAX_EXEC_TIME=10

# # change the path color
# zstyle :prompt:pure:path color white

# # change the color for both `prompt:success` and `prompt:error`
# zstyle ':prompt:pure:prompt:*' color cyan

# # turn on git stash status
# zstyle :prompt:pure:git:stash show yes
# zstyle :prompt:pure:path color '#FF0000'

# prompt pure

# manually installed Pg from https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
# export PATH="/Library/PostgreSQL/15/bin:$PATH"

export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/lpuharic1/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/lpuharic1/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/lpuharic1/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/lpuharic1/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

PATH=~/.console-ninja/.bin:$PATH
source ~/.lcldevrc
