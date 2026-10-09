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
    ~/work-cert \
    ~/migration/home
# ~/work-cert has the work CA certs: .gitconfig uses work-root-ca.crt, ~/.extra points SSL_CERT_FILE etc at CABundle.pem
# ~/.ssh minus the agent socket and config.d (root-owned and unreadable, the bootstrap tool regenerates it)
rsync -a --exclude agent --exclude config.d ~/.ssh ~/migration/home/
cp -Rp ~/Library/Application\ Support/zoxide ~/migration/Library/"Application Support"/ # zoxide's directory db

# lolcommits: photos and per-repo config live in ~/.lolcommits, the post-commit hooks live in each repo's .git
# so also list the repos (relative to ~) that have it enabled, setup-a-new-machine.sh re-enables them
cp -Rp ~/.lolcommits ~/migration/home
find ~/GitHub ~/workgit -maxdepth 5 -path '*/.git/hooks/post-commit' -exec grep -l lolcommits {} + 2>/dev/null \
    | sed -e 's#/\.git/hooks/post-commit$##' -e "s#^$HOME/##" > ~/migration/lolcommits-repos.txt

# Documents and Desktop aren't copied, they sync via iCloud

# claude code: all of ~/.claude (settings, plugins, plans, history, and per-project memory + transcripts so
# /resume works), minus per-machine state and caches. the login is in the keychain, run /login on the new machine
# projects/ is keyed by path (-Users-<you>-workgit-cvp), so keep the same username and folder layout
rsync -a \
    --exclude sessions --exclude session-env --exclude shell-snapshots --exclude daemon --exclude daemon.log \
    --exclude debug --exclude ide --exclude paste-cache --exclude statsig --exclude .last-cleanup --exclude .DS_Store \
    --exclude tasks --exclude backups --exclude 'settings.json.backup.*' --exclude '.claude.json*' \
    --exclude plugins/marketplaces \
    ~/.claude ~/migration/home/
# ~/.claude.json also holds a machine id and caches, so only take the user MCP servers and per-project
# settings (trust, allowed tools, project MCP servers)
python3 - > ~/migration/home/claude.json <<'EOF'
import json, os, sys
config = json.load(open(os.path.expanduser("~/.claude.json")))
keys = ("hasTrustDialogAccepted", "allowedTools", "mcpServers", "enabledMcpjsonServers", "disabledMcpjsonServers")
projects = {path: {k: v[k] for k in keys if v.get(k)} for path, v in config.get("projects", {}).items()}
json.dump({"mcpServers": config.get("mcpServers", {}), "projects": {p: v for p, v in projects.items() if v}}, sys.stdout, indent=2)
EOF

# git repos under ~/GitHub/<user>/ and ~/workgit/, as "<path relative to ~> <origin url>" per line,
# setup-a-new-machine.sh clones them again. committed CLAUDE.md, .claude/skills etc come back that way
for repo in ~/GitHub/*/*/.git ~/workgit/*/.git; do
    repo="${repo%/.git}"
    url="$(git -C "$repo" remote get-url origin 2>/dev/null)" && echo "${repo#"$HOME"/} $url"
done > ~/migration/repos.txt

# claude files in those repos that git doesn't have (.claude/settings.local.json, CLAUDE.local.md, untracked
# CLAUDE.md / .mcp.json / .claude/*), kept at the same path under ~/migration/repos/
while read -r repo url; do
    git -C ~/"$repo" ls-files --others -- .claude CLAUDE.md CLAUDE.local.md .mcp.json \
        ':!:**/__pycache__/**' ':!:**/.mypy_cache/**' \
        | rsync -a --files-from=- ~/"$repo"/ ~/migration/repos/"$repo"/
done < ~/migration/repos.txt
# folders under ~/workgit that aren't git repos won't be cloned, copy them over by hand if you need them
find ~/workgit -mindepth 1 -maxdepth 1 -type d ! -exec test -d {}/.git \; -print

# work that isn't pushed yet won't come back with the clone, push it (or copy the repo) first
while read -r repo url; do
    dirty="$(git -C ~/"$repo" status --porcelain -- . ':!:.claude/settings.local.json' \
        ':!:**/__pycache__/**' ':!:**/.mypy_cache/**' | head -1)"
    unpushed="$(git -C ~/"$repo" log --branches --not --remotes --oneline | head -1)"
    [ -n "$dirty$unpushed" ] && echo "unpushed or uncommitted: ~/$repo"
done < ~/migration/repos.txt

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
