#!/usr/bin/env bash
# backup old machine's key items into ~/migration, then copy that folder over to the new machine
# run this on the old machine. setup-a-new-machine.sh restores it

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/migration/home/
mkdir -p ~/migration/Library/"Application Support"/Code/

cd ~/migration || exit

# user info, read from this machine's git config and the dotfiles remote
#   personal identity: ~/.gitconfig.local (used for repos under ~/GitHub)
#   work identity:     the [user] block in .gitconfig (the default everywhere else)
#   github user:       owner of this repo's origin remote
GITHUB_USER="$(git -C "$DOTFILES_DIR" remote get-url origin | sed -E 's#^.*github\.com[:/]([^/]+)/.*$#\1#')"
DOTFILES_REPO="$(basename "$DOTFILES_DIR")"
PERSONAL_NAME="$(git config --file ~/.gitconfig.local user.name)"
PERSONAL_EMAIL="$(git config --file ~/.gitconfig.local user.email)"
WORK_NAME="$(git config --file ~/.gitconfig user.name)"
WORK_EMAIL="$(git config --file ~/.gitconfig user.email)"

# saved as a sourceable file so setup-a-new-machine.sh can use it
{
    echo "# user info from the old machine, written by backup-old-machine.sh"
    printf 'GITHUB_USER=%q\n' "$GITHUB_USER"
    printf 'DOTFILES_REPO=%q\n' "$DOTFILES_REPO"
    printf 'PERSONAL_NAME=%q\n' "$PERSONAL_NAME"
    printf 'PERSONAL_EMAIL=%q\n' "$PERSONAL_EMAIL"
    printf 'WORK_NAME=%q\n' "$WORK_NAME"
    printf 'WORK_EMAIL=%q\n' "$WORK_EMAIL"
} > ~/migration/user-info.sh
cat ~/migration/user-info.sh

# what is worth reinstalling?
# the Brewfile is the list of brew formulae, casks, vscode extensions and npm globals. this lists anything
# installed that isn't in it (without --force it only lists), add those to the Brewfile and commit
brew bundle cleanup --file="$HOME/Brewfile"

# dotfiles not under source control
# ~/.gitconfig.local is a symlink into this repo (gitignored), so copy the real file
cp -p "$(readlink ~/.gitconfig.local)" ~/migration/home/.gitconfig.local
cp -Rp \
    ~/.bash_history \
    ~/.zsh_history \
    ~/.extra \
    ~/.ssh \
    ~/migration/home
cp -Rp ~/Library/Application\ Support/zoxide ~/migration/Library/"Application Support"/ # zoxide's directory db

# lolcommits: photos and per-repo config live in ~/.lolcommits, the post-commit hooks live in each repo's .git
# so also list the repos (relative to ~) that have it enabled, setup-a-new-machine.sh re-enables them
cp -Rp ~/.lolcommits ~/migration/home
find ~/GitHub ~/BBGitHub -maxdepth 5 -path '*/.git/hooks/post-commit' -exec grep -l lolcommits {} + 2>/dev/null \
    | sed -e 's#/\.git/hooks/post-commit$##' -e "s#^$HOME/##" > ~/migration/lolcommits-repos.txt

# Documents and Desktop aren't copied, they sync via iCloud

# claude code: user settings, plugins, per-project memory and the user-scoped MCP servers
# skips conversation transcripts, history and caches. the login is in the keychain, run /login on the new machine
mkdir -p ~/migration/home/.claude
cp -p ~/.claude/settings.json ~/migration/home/.claude/
for f in CLAUDE.md keybindings.json agents commands skills hooks output-styles plugins; do
    [ -e ~/.claude/"$f" ] && cp -Rp ~/.claude/"$f" ~/migration/home/.claude/
done
# memory dirs are keyed by project path (projects/-Users-<you>-.../memory), so they match if the paths do
(cd ~/.claude && find projects -mindepth 2 -maxdepth 2 -type d -name memory -exec rsync -aR {} ~/migration/home/.claude/ \;)
# ~/.claude.json also holds a machine id and caches, so only take mcpServers
python3 -c 'import json, os, sys; json.dump({"mcpServers": json.load(open(os.path.expanduser("~/.claude.json"))).get("mcpServers", {})}, sys.stdout, indent=2)' \
    > ~/migration/home/claude-mcp-servers.json

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
