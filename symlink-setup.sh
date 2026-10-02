#!/bin/bash

# this symlinks all the dotfiles (and .vim/) to ~/
# it also symlinks ~/bin for easy updating

# this is safe to run multiple times and will prompt you about anything unclear


# this is a messy edit of alrra's nice work here:
#   https://raw.githubusercontent.com/alrra/dotfiles/master/os/create_symbolic_links.sh
#   it should and needs to be improved to be less of a hack.



# jump down to line ~140 for the start.



#
# utils !!!
#


answer_is_yes() {
    [[ "$REPLY" =~ ^[Yy]$ ]] \
        && return 0 \
        || return 1
}

ask() {
    print_question "$1"
    read
}

ask_for_confirmation() {
    print_question "$1 (y/n) "
    read -n 1
    printf "\n"
}

ask_for_sudo() {

    # Ask for the administrator password upfront
    sudo -v

    # Update existing `sudo` time stamp until this script has finished
    # https://gist.github.com/cowboy/3118588
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done &> /dev/null &

}

cmd_exists() {
    [ -x "$(command -v "$1")" ] \
        && printf 0 \
        || printf 1
}

execute() {
    $1 &> /dev/null
    print_result $? "${2:-$1}"
}

get_answer() {
    printf "$REPLY"
}

get_os() {

    declare -r OS_NAME="$(uname -s)"
    local os=""

    if [ "$OS_NAME" == "Darwin" ]; then
        os="osx"
    elif [ "$OS_NAME" == "Linux" ] && [ -e "/etc/lsb-release" ]; then
        os="ubuntu"
    fi

    printf "%s" "$os"

}

is_git_repository() {
    [ "$(git rev-parse &>/dev/null; printf $?)" -eq 0 ] \
        && return 0 \
        || return 1
}

mkd() {
    if [ -n "$1" ]; then
        if [ -e "$1" ]; then
            if [ ! -d "$1" ]; then
                print_error "$1 - a file with the same name already exists!"
            else
                print_success "$1"
            fi
        else
            execute "mkdir -p $1" "$1"
        fi
    fi
}

print_error() {
    # Print output in red
    printf "\e[0;31m  [✖] $1 $2\e[0m\n"
}

print_info() {
    # Print output in purple
    printf "\n\e[0;35m $1\e[0m\n\n"
}

print_question() {
    # Print output in yellow
    printf "\e[0;33m  [?] $1\e[0m"
}

print_result() {
    [ "$1" -eq 0 ] \
        && print_success "$2" \
        || print_error "$2"

    [ "$3" == "true" ] && [ "$1" -ne 0 ] \
        && exit
}

print_success() {
    # Print output in green
    printf "\e[0;32m  [✔] $1\e[0m\n"
}






#
# actual symlink stuff
#


# finds all .dotfiles in this folder
declare -a FILES_TO_SYMLINK=$(find . -type f -maxdepth 1 -name ".*" -not -name .DS_Store -not -name .git -not -name .osx | sed -e 's|//|/|' | sed -e 's|./.|.|')
FILES_TO_SYMLINK="$FILES_TO_SYMLINK .vim bin .gitignore_global Brewfile " # add in vim and the binaries


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    local i=""
    local sourceFile=""
    local targetFile=""

    for i in ${FILES_TO_SYMLINK[@]}; do

        sourceFile="$(pwd)/$i"
        targetFile="$HOME/$(printf "%s" "$i" | sed "s/.*\/\(.*\)/\1/g")"

        if [ -e "$targetFile" ]; then
            if [ "$(readlink "$targetFile")" != "$sourceFile" ]; then

                ask_for_confirmation "'$targetFile' already exists, do you want to overwrite it?"
                if answer_is_yes; then
                    rm -rf "$targetFile"
                    execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
                else
                    print_error "$targetFile → $sourceFile"
                fi

            else
                print_success "$targetFile → $sourceFile"
            fi
        else
            execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
        fi

    done

}

main

# eza theme (eza/theme.yml symlinks to the active one in eza/themes/)
mkdir -p "$HOME/.config/eza"
execute "ln -fs $(pwd)/eza/theme.yml $HOME/.config/eza/theme.yml" "$HOME/.config/eza/theme.yml → $(pwd)/eza/theme.yml"

# bat config and themes (whole folder), then rebuild bat's theme cache
if [ -e "$HOME/.config/bat" ] && [ "$(readlink "$HOME/.config/bat")" != "$(pwd)/bat" ]; then
    ask_for_confirmation "'$HOME/.config/bat' already exists, do you want to overwrite it?"
    if answer_is_yes; then
        rm -rf "$HOME/.config/bat"
        execute "ln -fs $(pwd)/bat $HOME/.config/bat" "$HOME/.config/bat → $(pwd)/bat"
    else
        print_error "$HOME/.config/bat → $(pwd)/bat"
    fi
elif [ ! -e "$HOME/.config/bat" ]; then
    execute "ln -fs $(pwd)/bat $HOME/.config/bat" "$HOME/.config/bat → $(pwd)/bat"
fi
command -v bat >/dev/null 2>&1 && bat cache --build >/dev/null

# ghostty config (whole folder). ghostty also reads ~/Library/Application Support/com.mitchellh.ghostty/config
# and that one wins, so don't keep a config there
if [ -e "$HOME/.config/ghostty" ] && [ "$(readlink "$HOME/.config/ghostty")" != "$(pwd)/ghostty" ]; then
    ask_for_confirmation "'$HOME/.config/ghostty' already exists, do you want to overwrite it?"
    if answer_is_yes; then
        rm -rf "$HOME/.config/ghostty"
        execute "ln -fs $(pwd)/ghostty $HOME/.config/ghostty" "$HOME/.config/ghostty → $(pwd)/ghostty"
    else
        print_error "$HOME/.config/ghostty → $(pwd)/ghostty"
    fi
elif [ ! -e "$HOME/.config/ghostty" ]; then
    execute "ln -fs $(pwd)/ghostty $HOME/.config/ghostty" "$HOME/.config/ghostty → $(pwd)/ghostty"
fi

# iterm loads and saves its settings in iterm/ (it can't use a symlink, so point it at the folder)
# run before opening iterm, or restart it after
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$(pwd)/iterm"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
# save changes back to iterm/ automatically
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2
print_success "iterm settings → $(pwd)/iterm"
