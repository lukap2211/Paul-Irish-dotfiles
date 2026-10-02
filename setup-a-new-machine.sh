# copy paste this file in bit by bit.
# don't run it.
echo "do not run this script in one go. hit ctrl-c NOW"
read -n 1


##############################################################################################################
### backup old machine's key items (run on the old machine)

mkdir -p ~/migration/home/
mkdir -p ~/migration/Library/"Application Support"/Code/

cd ~/migration || exit

# what is worth reinstalling?
# the Brewfile is the list of brew formulae, casks and vscode extensions. this lists anything
# installed that isn't in it (without --force it only lists), add those to the Brewfile and commit
brew bundle cleanup --file="$HOME/Brewfile"
npm list -g --depth=0 > npm-g-list.txt

# dotfiles not under source control
# ~/.gitconfig.local is a symlink into this repo (gitignored), so copy the real file
cp -p "$(readlink ~/.gitconfig.local)" ~/migration/home/.gitconfig.local
cp -Rp \
    ~/.bash_history \
    ~/.zsh_history \
    ~/.extra \
    ~/.ssh \
    ~/.z \
    ~/migration/home

cp -Rp ~/Documents ~/migration
cp -Rp ~/Pictures ~/migration

cp -Rp ~/Library/Services ~/migration/Library/ # automator stuff
cp -Rp ~/Library/Fonts ~/migration/Library/    # all those fonts you've installed

# vscode settings, keybindings and snippets (extensions are in the Brewfile)
# skip caches and local history, they're most of the ~1GB
rsync -a --exclude workspaceStorage --exclude globalStorage --exclude History \
    ~/Library/Application\ Support/Code/User ~/migration/Library/"Application Support"/Code/

# also check for
#   git branches you never pushed anywhere
#   untracked or gitignored files in your repos you want to keep
#   uncommitted changes in this repo, iterm/ included (iTerm saves its settings there)

### end of old machine backup
##############################################################################################################


##############################################################################################################
### XCode Command Line Tools
# git, make, clang etc. the homebrew installer also does this if they're missing

xcode-select --install


##############################################################################################################
### homebrew
# install homebrew first, see https://brew.sh/
# brew.sh runs `brew bundle` on ./Brewfile (also symlinked to ~/Brewfile by symlink-setup.sh)

./brew.sh


##############################################################################################################
### npm globals

# Type `git open` to open the GitHub page or website for a repository.
npm install -g git-open

# fancy listing of recent branches
npm install -g git-recent

# sexy git diffs (.gitconfig pipes diff/show through it)
npm install -g diff-so-fancy

# trash as the safe `rm` alternative
npm install -g trash-cli


##############################################################################################################
### git

git config user.email "lukap2211@gmail.com"


##############################################################################################################
### macOS defaults

sh .osx


##############################################################################################################
### symlinks to link dotfiles into ~/

# git credentials live in ~/.gitconfig.local (http://stackoverflow.com/a/13615531/89484)
# so .gitconfig can be shared across all machines and only the .local changes

./symlink-setup.sh

# install vim plugins (vim-plug is in .vim/autoload, plugins go in .vim/plugged)
vim +PlugInstall +qall

# ~/.ssh/config isn't linked, see .ssh.config.example


##############################################################################################################
### zsh
# the login shell is macOS's /bin/zsh (the default), nothing to change

# oh my zsh. custom themes/plugins are loaded from ./oh-my-zsh via ZSH_CUSTOM in .zshrc
git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME"/.oh-my-zsh
