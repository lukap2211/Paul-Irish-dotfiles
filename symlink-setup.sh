#!/bin/bash

# this symlinks all the dotfiles (and .vim/, bin/, Brewfile) to ~/ and a few folders into ~/.config/
# it also points iTerm at iterm/ for its settings

# this is safe to run multiple times and will ask before replacing anything that isn't already linked here

# started as a messy edit of alrra's nice work here:
#   https://raw.githubusercontent.com/alrra/dotfiles/master/os/create_symbolic_links.sh


# everything below is relative to the repo, so it works from any folder
cd "$(dirname "$0")" || exit
DOTFILES="$(pwd)"


#
# utils
#

answer_is_yes() {
    [[ "$REPLY" =~ ^[Yy]$ ]]
}

ask_for_confirmation() {
    print_question "$1 (y/n) "
    read -n 1
    printf "\n"
}

print_error() {
    # Print output in red
    printf "\e[0;31m  [✖] $1 $2\e[0m\n"
}

print_question() {
    # Print output in yellow
    printf "\e[0;33m  [?] $1\e[0m"
}

print_result() {
    [ "$1" -eq 0 ] \
        && print_success "$2" \
        || print_error "$2"
}

print_success() {
    # Print output in green
    printf "\e[0;32m  [✔] $1\e[0m\n"
}

# link <source> <target>: makes target a symlink to source, asks before replacing anything else
link() {
    local sourceFile="$1"
    local targetFile="$2"

    if [ -e "$targetFile" ] && [ "$(readlink "$targetFile")" != "$sourceFile" ]; then
        ask_for_confirmation "'$targetFile' already exists, do you want to overwrite it?"
        if ! answer_is_yes; then
            print_error "$targetFile → $sourceFile"
            return
        fi
        rm -rf "$targetFile"
    fi

    ln -sfn "$sourceFile" "$targetFile" &> /dev/null
    print_result $? "$targetFile → $sourceFile"
}


#
# actual symlink stuff
#

# all .dotfiles at the top of the repo, except the repo's own git files and examples
for file in $(find . -maxdepth 1 -type f -name ".*" \
        -not -name .DS_Store \
        -not -name .osx \
        -not -name .gitignore \
        -not -name .gitmodules \
        -not -name .ssh.config.example \
        | sed 's|^\./||' | sort); do
    link "$DOTFILES/$file" "$HOME/$file"
done

# vim, the binaries and the Brewfile
for file in .vim bin Brewfile; do
    link "$DOTFILES/$file" "$HOME/$file"
done

mkdir -p "$HOME/.config/eza"

# eza theme (eza/theme.yml symlinks to the active one in eza/themes/)
link "$DOTFILES/eza/theme.yml" "$HOME/.config/eza/theme.yml"

# bat config and themes (whole folder), then rebuild bat's theme cache
link "$DOTFILES/bat" "$HOME/.config/bat"
command -v bat >/dev/null 2>&1 && bat cache --build >/dev/null

# ghostty config (whole folder). ghostty also reads ~/Library/Application Support/com.mitchellh.ghostty/config
# and that one wins, so don't keep a config there
link "$DOTFILES/ghostty" "$HOME/.config/ghostty"

# iterm loads and saves its settings in iterm/ (it can't use a symlink, so point it at the folder)
# run before opening iterm, or restart it after
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES/iterm"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
# save changes back to iterm/ automatically
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2
print_success "iterm settings → $DOTFILES/iterm"
