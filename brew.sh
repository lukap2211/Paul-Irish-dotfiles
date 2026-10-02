#!/bin/bash

# Install command-line tools using Homebrew
# The Brewfile is the source of truth for formulae/casks/extensions -- add new installs there.
# Homebrew itself isn't installed here: on a bloomberg machine bb_bootstrap installs homebrew and node,
# otherwise see https://brew.sh/

# Make sure we’re using the latest Homebrew
brew update

# Install (and upgrade) everything in the Brewfile
brew bundle --file="$(dirname "$0")/Brewfile"


# Extra setup the Brewfile can't express

# allow mtr to run without sudo (the raw-socket work is done by mtr-packet)
mtrpacket="$(brew --prefix mtr)/sbin/mtr-packet"
sudo chown root "$mtrpacket"
sudo chmod 4755 "$mtrpacket"

# ruby lolcommits (uses imagemagick from the Brewfile)
sudo gem install lolcommits

# Remove outdated versions from the cellar
brew cleanup
