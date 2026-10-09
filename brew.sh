#!/bin/bash

# Install command-line tools using Homebrew
# The Brewfile is the source of truth for formulae/casks/extensions -- add new installs there.
# Homebrew itself isn't installed here, see https://brew.sh/ (a work machine's own bootstrap may already do it)

# Make sure we’re using the latest Homebrew
brew update

# Install (and upgrade) everything in the Brewfile
brew bundle --file="$(dirname "$0")/Brewfile"


# Extra setup the Brewfile can't express

# ruby lolcommits (uses imagemagick from the Brewfile)
sudo gem install lolcommits

# Remove outdated versions from the cellar
brew cleanup
