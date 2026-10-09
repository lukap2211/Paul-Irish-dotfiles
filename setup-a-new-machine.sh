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

# GITHUB_USER, DOTFILES_REPO, PERSONAL_NAME, PERSONAL_EMAIL
source ~/migration/user-info.sh

# work extras, if the backup has work/ (see the README): EXTRA_HOME, CLONE_OPTS, GH_HOSTS, SSH_CHECKS
EXTRA_HOME=() CLONE_OPTS=() GH_HOSTS=() SSH_CHECKS=()
[ -f ~/migration/work/env.sh ] && source ~/migration/work/env.sh

cp -Rp \
    home/.bash_history \
    home/.zsh_history \
    home/.extra \
    home/.ssh \
    home/.lolcommits \
    ~/
for dir in "${EXTRA_HOME[@]}"; do cp -Rp home/"$dir" ~/; done
# ssh refuses keys others can read. folders (e.g. one per key) need 700 or the key inside can't be opened
find ~/.ssh -type d -exec chmod 700 {} +
find ~/.ssh -type f -exec chmod 600 {} +
find ~/.ssh -name '*.pub' -exec chmod 644 {} +

# Documents and Desktop come back via iCloud, sign in to it to start the sync

# claude code: ~/.claude (settings, plugins, memory, transcripts, history), then merge the MCP servers and
# per-project settings into ~/.claude.json (created if missing). run /login in claude afterwards, the login
# isn't migrated. the per-repo .claude/settings.local.json files come back once the repos are cloned, see below
mkdir -p ~/.claude
cp -Rp home/.claude/. ~/.claude/
python3 - <<'EOF'
import json, os
path = os.path.expanduser("~/.claude.json")
config = json.load(open(path)) if os.path.exists(path) else {}
backup = json.load(open("home/claude.json"))
config.setdefault("mcpServers", {}).update(backup["mcpServers"])
for project, settings in backup["projects"].items():
    config.setdefault("projects", {}).setdefault(project, {}).update(settings)
json.dump(config, open(path, "w"), indent=2)
EOF
cp -Rp Library/Services Library/Fonts ~/Library/
mkdir -p ~/Library/"Application Support"/Code/
cp -Rp Library/"Application Support"/Code/User ~/Library/"Application Support"/Code/
cp -Rp Library/"Application Support"/zoxide ~/Library/"Application Support"/


##############################################################################################################
### clone this repo
# over https (the .gitconfig that rewrites ssh urls isn't linked yet). behind a proxy, CLONE_OPTS from work/env.sh
# passes the proxy settings on the command line

mkdir -p ~/GitHub/"$GITHUB_USER"
git "${CLONE_OPTS[@]}" clone --recursive \
    https://github.com/"$GITHUB_USER/$DOTFILES_REPO".git ~/GitHub/"$GITHUB_USER/$DOTFILES_REPO"
cd ~/GitHub/"$GITHUB_USER/$DOTFILES_REPO" || exit
git remote add upstream https://github.com/paulirish/dotfiles.git

# gitignored, live in the repo and get symlinked to ~/ by symlink-setup.sh, so they have to be here first
# if the backup has no .gitconfig.local, create it with the personal identity
if [ -f ~/migration/home/.gitconfig.local ]; then
    cp -p ~/migration/home/.gitconfig.local .
else
    git config --file .gitconfig.local user.name "$PERSONAL_NAME"
    git config --file .gitconfig.local user.email "$PERSONAL_EMAIL"
fi
[ -d ~/migration/work ] && cp -Rp ~/migration/work .


##############################################################################################################
### homebrew
# install homebrew first, see https://brew.sh/ (or the work machine's own bootstrap, see work/README.md)
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

# the personal git identity lives in ~/.gitconfig.local (http://stackoverflow.com/a/13615531/89484)
# so .gitconfig can be shared across all machines and only the .local changes
# ~/.gitconfig.work (from work/) has the default work identity, ~/.gitconfig.local (personal) is used for repos
# under ~/GitHub

./symlink-setup.sh

# install vim plugins (vim-plug is in .vim/autoload, plugins go in .vim/plugged)
vim +PlugInstall +qall

# ~/.ssh/config isn't linked, it came back with ~/.ssh (see .ssh.config.example, and work/ for work hosts)


##############################################################################################################
### clone the rest of your repos (~/GitHub/<user>/*, plus the work folders from work/env.sh)
# github.com goes over https with the token from gh, so log in first. then the extra gh logins and ssh checks
# from work/env.sh (see work/README.md for what to run before them)

gh auth login -h github.com
for host in "${GH_HOSTS[@]}"; do gh auth login -h "$host"; done
for login in "${SSH_CHECKS[@]}"; do ssh -T "$login"; done

# skips any that already exist (this repo)
while read -r repo url; do
    [ -d ~/"$repo" ] || git clone "$url" ~/"$repo"
done < ~/migration/repos.txt

# claude files git doesn't have (.claude/settings.local.json etc), back to the same path in each repo
[ -d ~/migration/repos ] && cp -Rp ~/migration/repos/. ~/

# the claude hooks in ~/.claude/settings.json call ~/.config/iterm2/cc-status (iTerm's claude status helper)
mkdir -p ~/.config/iterm2
ln -sf /Applications/iTerm.app/Contents/Resources/utilities/cc-status ~/.config/iterm2/cc-status


##############################################################################################################
### lolcommits
# brew.sh installs it and ~/.lolcommits came back with the restore. the post-commit hooks don't,
# so once your repos are cloned again re-enable it in the ones that had it (skips any not cloned yet)

while read -r repo; do
    [ -d ~/"$repo"/.git ] && (cd ~/"$repo" && lolcommits --enable)
done < ~/migration/lolcommits-repos.txt
