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
# the Brewfile is the list of brew formulae, casks, vscode extensions and npm globals. this lists anything
# installed that isn't in it (without --force it only lists), add those to the Brewfile and commit
brew bundle cleanup --file="$HOME/Brewfile"

# dotfiles not under source control
# ~/.gitconfig.local and ~/.gitconfig.work are symlinks into this repo (gitignored), so copy the real files
cp -p "$(readlink ~/.gitconfig.local)" ~/migration/home/.gitconfig.local
cp -p "$(readlink ~/.gitconfig.work)" ~/migration/home/.gitconfig.work
cp -Rp \
    ~/.bash_history \
    ~/.zsh_history \
    ~/.extra \
    ~/.ssh \
    ~/migration/home
cp -Rp ~/Library/Application\ Support/zoxide ~/migration/Library/"Application Support"/ # zoxide's directory db

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
### restore the backup (copy ~/migration over from the old machine first)

cd ~/migration || exit

cp -Rp \
    home/.bash_history \
    home/.zsh_history \
    home/.extra \
    home/.ssh \
    ~/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub

cp -Rp Documents Pictures ~/
cp -Rp Library/Services Library/Fonts ~/Library/
mkdir -p ~/Library/"Application Support"/Code/
cp -Rp Library/"Application Support"/Code/User ~/Library/"Application Support"/Code/
cp -Rp Library/"Application Support"/zoxide ~/Library/"Application Support"/


##############################################################################################################
### clone this repo (ssh works now that ~/.ssh is back)

mkdir -p ~/GitHub/lukap2211
git clone --recursive git@github.com:lukap2211/Paul-Irish-dotfiles.git ~/GitHub/lukap2211/Paul-Irish-dotfiles
cd ~/GitHub/lukap2211/Paul-Irish-dotfiles || exit
git remote add upstream git@github.com:paulirish/dotfiles.git

# gitignored, live in the repo and get symlinked to ~/ by symlink-setup.sh, so they have to be here first
cp -p ~/migration/home/.gitconfig.local ~/migration/home/.gitconfig.work .


##############################################################################################################
### homebrew
# install homebrew first, see https://brew.sh/
# brew.sh runs `brew bundle` on ./Brewfile (also symlinked to ~/Brewfile by symlink-setup.sh)

./brew.sh


##############################################################################################################
### macOS defaults

bash .osx


##############################################################################################################
### zsh
# the login shell is macOS's /bin/zsh (the default), nothing to change

# oh my zsh. custom themes/plugins are loaded from ./oh-my-zsh via ZSH_CUSTOM in .zshrc
# install before the symlinks, the linked .zshrc sources it
git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME"/.oh-my-zsh


##############################################################################################################
### symlinks to link dotfiles into ~/

# git credentials live in ~/.gitconfig.local (http://stackoverflow.com/a/13615531/89484)
# so .gitconfig can be shared across all machines and only the .local changes
# repos under ~/workgit use the work identity in ~/.gitconfig.work instead

./symlink-setup.sh

# install vim plugins (vim-plug is in .vim/autoload, plugins go in .vim/plugged)
vim +PlugInstall +qall

# ~/.ssh/config isn't linked, see .ssh.config.example
