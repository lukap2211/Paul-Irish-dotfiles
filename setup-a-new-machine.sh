# copy paste this file in bit by bit.
# don't run it.
echo "do not run this script in one go. hit ctrl-c NOW"
read -n 1


##############################################################################################################
### backup old machine's key items (run on the old machine, from this repo)
# copies everything worth keeping into ~/migration, including user-info.sh with your github user and git identities

./backup-old-machine.sh


##############################################################################################################
### XCode Command Line Tools
# git, make, clang etc. the homebrew installer also does this if they're missing

xcode-select --install


##############################################################################################################
### restore the backup (copy ~/migration over from the old machine first)

cd ~/migration || exit

# GITHUB_USER, DOTFILES_REPO, PERSONAL_NAME, PERSONAL_EMAIL, WORK_NAME, WORK_EMAIL
source ~/migration/user-info.sh

cp -Rp \
    home/.bash_history \
    home/.zsh_history \
    home/.extra \
    home/.ssh \
    home/.lolcommits \
    ~/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub

# Documents and Desktop come back via iCloud, sign in to it to start the sync

# claude code settings, plugins and memory, then merge the MCP servers into ~/.claude.json (created if missing)
# run /login in claude afterwards, the login isn't migrated
mkdir -p ~/.claude
cp -Rp home/.claude/. ~/.claude/
python3 - <<'EOF'
import json, os
path = os.path.expanduser("~/.claude.json")
config = json.load(open(path)) if os.path.exists(path) else {}
config.setdefault("mcpServers", {}).update(json.load(open("home/claude-mcp-servers.json"))["mcpServers"])
json.dump(config, open(path, "w"), indent=2)
EOF
cp -Rp Library/Services Library/Fonts ~/Library/
mkdir -p ~/Library/"Application Support"/Code/
cp -Rp Library/"Application Support"/Code/User ~/Library/"Application Support"/Code/
cp -Rp Library/"Application Support"/zoxide ~/Library/"Application Support"/


##############################################################################################################
### clone this repo (ssh works now that ~/.ssh is back)

mkdir -p ~/GitHub/"$GITHUB_USER"
git clone --recursive git@github.com:"$GITHUB_USER/$DOTFILES_REPO".git ~/GitHub/"$GITHUB_USER/$DOTFILES_REPO"
cd ~/GitHub/"$GITHUB_USER/$DOTFILES_REPO" || exit
git remote add upstream git@github.com:paulirish/dotfiles.git

# gitignored, lives in the repo and gets symlinked to ~/ by symlink-setup.sh, so it has to be here first
# if the backup has none, create it with the personal identity
if [ -f ~/migration/home/.gitconfig.local ]; then
    cp -p ~/migration/home/.gitconfig.local .
else
    git config --file .gitconfig.local user.name "$PERSONAL_NAME"
    git config --file .gitconfig.local user.email "$PERSONAL_EMAIL"
fi

# the work identity is the [user] block in .gitconfig, set it to the old machine's (no-op if unchanged)
git config --file .gitconfig user.email "$WORK_EMAIL"
git config --file .gitconfig user.name "$WORK_NAME"


##############################################################################################################
### homebrew
# install homebrew first, see https://brew.sh/
# on a work machine the work bootstrap installs homebrew and node, so skip that and run brew.sh after it
# brew.sh runs `brew bundle` on ./Brewfile (also symlinked to ~/Brewfile by symlink-setup.sh)

./brew.sh


##############################################################################################################
### macOS defaults

bash .macos


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
# .gitconfig has the work identity, ~/.gitconfig.local (personal) is only used for repos under ~/GitHub

./symlink-setup.sh

# install vim plugins (vim-plug is in .vim/autoload, plugins go in .vim/plugged)
vim +PlugInstall +qall

# ~/.ssh/config isn't linked, see .ssh.config.example


##############################################################################################################
### lolcommits
# brew.sh installs it and ~/.lolcommits came back with the restore. the post-commit hooks don't,
# so once your repos are cloned again re-enable it in the ones that had it (skips any not cloned yet)

while read -r repo; do
    [ -d ~/"$repo"/.git ] && (cd ~/"$repo" && lolcommits --enable)
done < ~/migration/lolcommits-repos.txt
