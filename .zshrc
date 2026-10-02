# uncomment to profile prompt startup with zprof (and the zprof line at the bottom)
# zmodload zsh/zprof


######################################################################
### PATH

# drop duplicate PATH entries (nested shells, brew shellenv in .workdevrc too)
typeset -U path PATH

# arm64 homebrew, also adds its zsh site-functions to fpath
eval "$(/opt/homebrew/bin/brew shellenv)"

# python3 unversioned symlinks (python, pip), follows the installed python@3
export PATH=/opt/homebrew/opt/python@3/libexec/bin:$PATH

export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"


######################################################################
### shell options

# vim bindings
bindkey -v

# history, shared between sessions
# http://www.refining-linux.org/archives/49/ZSH-Gem-15-Shared-history/
SAVEHIST=100000
setopt inc_append_history
setopt share_history

# case-insensitive, then partial-word and substring completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Automatically list directory contents on `cd`.
auto-ls () {
	emulate -L zsh;
	# explicit sexy ls'ing as aliases arent honored in here.
	eza --classify=auto --color=always --group-directories-first --sort=extension -A
}
chpwd_functions=( auto-ls $chpwd_functions )


######################################################################
### oh-my-zsh

export ZSH="$HOME/.oh-my-zsh"

# Custom themes/plugins live in the dotfiles repo (resolved via the ~/.zshrc symlink)
ZSH_CUSTOM="${${(%):-%x}:A:h}/oh-my-zsh"

# https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="strug"
# ZSH_THEME="lukap2211"

# Add wisely, as too many plugins slow down shell startup.
plugins=(
  macos
  gh
  git
  brew
  aws
  azure
  docker
  docker-compose
  zsh-interactive-cd
  zsh-navigation-tools
)

source $ZSH/oh-my-zsh.sh


######################################################################
### everything else

# Load default dotfiles
source ~/.bash_profile

[ -r ~/.workdevrc ] && source ~/.workdevrc

# Google Cloud SDK: PATH and gcloud completion
[ -f ~/Downloads/google-cloud-sdk/path.zsh.inc ] && source ~/Downloads/google-cloud-sdk/path.zsh.inc
[ -f ~/Downloads/google-cloud-sdk/completion.zsh.inc ] && source ~/Downloads/google-cloud-sdk/completion.zsh.inc

# installed with homebrew. syntax highlighting has to be sourced last, after every other widget is defined
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# uncomment to finish profiling
# zprof
