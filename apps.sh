#!/bin/bash

brews=(
  bash
  caskroom/cask/brew-cask
  dfc
  git
  git-extras
  htop
  mackup
  macvim
  node
  nmap
  python
  ruby
  scala
  sbt
  wget
  zsh
)

casks=(
  asepsis
  atom
  betterzipql
  cakebrew
  chromecast
  cleanmymac
  dropbox
  google-chrome
  google-drive
  github
  hosts
  firefox
  intellij-idea
  istat-menus
  istat-server
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  mtr
  java
  launchrocket
  plex-home-theater
  plex-media-server
  sidekick
  spotify
  steam
  teleport
  utorrent
  vlc
  zeroxdbe-eap
)

pips=(
  Glances
)

gems=(
  travis
)

npms=(
  grunt
  coffee-script
  trash
  gitjk
  fenix-cli
)

set +e

echo "Installing Xcode ..."
xcode-select --install

if hash brew 2> /dev/null; then
  echo "Updating Homebrew ..."
  brew update
else
  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi
brew doctor

fails=()

function error {
  red='\x1B[0;31m'
  NC='\x1B[0m' # no color
  msg="${red}Failed to execute: $1 $2${NC}"
  fails+=($2)
  echo -e $msg
}

function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    echo "Executing: $exec"
    if $exec ; then
      echo "Installed $pkg"
    else
      error $cmd $pkg
    fi
  done
}

install 'brew install' ${brews[@]}
install 'brew cask --appdir=/Applications install' ${casks[@]}
install 'pip install' ${pips[@]}
install 'gem install' ${gems[@]}
install 'npm install -g' ${npms[@]}

echo "Setting up zsh ..."
curl -L http://install.ohmyz.sh | sh
chsh -s $(which zsh)
# Use theme "ys" in ~/.zshrc

echo "Upgrading ..."
pip install --upgrade setuptools
pip install --upgrade pip
gem update --system

echo "Cleaning up ..."
git config --global pull.rebase true
brew cleanup
brew cask cleanup
brew linkapps

echo "Running OSX for Hackers ..."
curl -L https://gist.githubusercontent.com/brandonb927/3195465/raw/osx-for-hackers.sh | sh

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done

echo "Run `mackup restore` after DropBox has done syncing"
