# copy paste this file in bit by bit.
# don't run it.
  echo "do not run this script in one go. hit ctrl-c NOW"
  read -n 1


##############################################################################################################
###  backup old machine's key items

mkdir -p ~/migration/home/
mkdir -p ~/migration/Library/"Application Support"/Code/

cd ~/migration || exit

# what is worth reinstalling?
# the Brewfile is the list of brew formulae, casks and vscode extensions. this lists anything
# installed that isn't in it (without --force it only lists), add those to the Brewfile and commit
brew bundle cleanup --file="$HOME/Brewfile"
npm list -g --depth=0    > npm-g-list.txt

# backup some dotfiles likely not under source control
# ~/.gitconfig.local is a symlink into this repo (gitignored), so copy the real file
cp -p "$(readlink ~/.gitconfig.local)" ~/migration/home/.gitconfig.local
cp -Rp \
    ~/.bash_history \
    ~/.zsh_history \
    ~/.extra \
    ~/.ssh \
    ~/.z   \
        ~/migration/home

cp -Rp ~/Documents ~/migration

cp -Rp ~/Library/Services ~/migration/Library/ # automator stuff
cp -Rp ~/Library/Fonts ~/migration/Library/ # all those fonts you've installed

# vscode settings, keybindings and snippets (extensions are in the Brewfile)
# skip caches and local history, they're most of the ~1GB
rsync -a --exclude workspaceStorage --exclude globalStorage --exclude History \
    ~/Library/Application\ Support/Code/User ~/migration/Library/"Application Support"/Code/

# also consider...
# random git branches you never pushed anywhere?
# git untracked files (or local gitignored stuff). stuff you never added, but probably want..


# OneTab history pages, because chrome tabs are valuable.

# usage logs you've been keeping.

# iTerm settings.
  # in the repo (iterm/), symlink-setup.sh points iTerm at it. commit iterm/ before moving

# Finder settings and TotalFinder settings
#   Not sure how to do this yet. Really want to.

# Timestats chrome extension stats
#   chrome-extension://ejifodhjoeeenihgfpjijjmpomaphmah/options.html#_options
# 	gotta export into JSON through devtools:
#     copy(JSON.stringify(localStorage))
#     pbpaste > timestats-canary.json.txt

# software licenses.

# maybe ~/Pictures and such
cp -Rp ~/Pictures ~/migration

### end of old machine backup
##############################################################################################################


##############################################################################################################
### XCode Command Line Tools
# git, make, clang etc. the homebrew installer also does this if they're missing

xcode-select --install
###
##############################################################################################################


##############################################################################################################
### homebrew!
# ! OLD
# # (if your machine has /usr/local locked down (like google's), you can do this to place everything in ~/.homebrew
# mkdir $HOME/.homebrew && curl -L https://github.com/mxcl/homebrew/tarball/master | tar xz --strip 1 -C $HOME/.homebrew
# export PATH=$HOME/.homebrew/bin:$HOME/.homebrew/sbin:$PATH

# ! THE LATEST
# check https://brew.sh/

# install all the things
# brew.sh runs `brew bundle` on ./Brewfile (also symlinked to ~/Brewfile by symlink-setup.sh)
./brew.sh

### end of homebrew
##############################################################################################################


##############################################################################################################
### install of common things
###


# Type `git open` to open the GitHub page or website for a repository.
npm install -g git-open

# fancy listing of recent branches
npm install -g git-recent

# sexy git diffs
npm install -g diff-so-fancy

# trash as the safe `rm` alternative
npm install --global trash-cli


# change to bash 4 (installed by homebrew)
BASHPATH=$(brew --prefix)/bin/bash
#sudo echo $BASHPATH >> /etc/shells
sudo bash -c 'echo $(brew --prefix)/bin/bash >> /etc/shells'
chsh -s "$BASHPATH" # will set for current user only.
echo "$BASH_VERSION" # should be 4.x not the old 3.2.X
# Later, confirm iterm settings aren't conflicting.


###
##############################################################################################################


git config user.email "lukap2211@gmail.com"


##############################################################################################################
### remaining configuration
###

# set up osx defaults
#   maybe something else in here https://github.com/hjuutilainen/dotfiles/blob/master/bin/osx-user-defaults.sh
sh .osx

###
##############################################################################################################


##############################################################################################################
### symlinks to link dotfiles into ~/
###

#   move git credentials into ~/.gitconfig.local    	http://stackoverflow.com/a/13615531/89484
#   now .gitconfig can be shared across all machines and only the .local changes

# symlink it up!
./symlink-setup.sh

# install vim plugins (vim-plug is in .vim/autoload, plugins go in .vim/plugged)
vim +PlugInstall +qall

# add manual symlink for .ssh/config and probably .config/fish

###
##############################################################################################################


# Oh my zsh
git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME"/.oh-my-zsh

# Custom themes/plugins are loaded from ./oh-my-zsh via ZSH_CUSTOM in .zshrc
