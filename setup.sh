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

######################################## End of app list ########################################
set +e

echo "Installing Xcode ..."
xcode-select --install

if test ! $(which brew); then
  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
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

# TODO: Do a pre-install search to make sure these packages exist in remote

install 'brew install' ${brews[@]}
install 'brew cask --appdir=/Applications install' ${casks[@]}
install 'pip install' ${pips[@]}
install 'gem install' ${gems[@]}
install 'npm install -g' ${npms[@]}

echo "Setting up zsh ..."
curl -L http://install.ohmyz.sh | sh
chsh -s $(which zsh)
# TODO: Auto-set theme to "fino-time" in ~/.zshrc (using antigen?)

echo "Upgrading ..."
pip install --upgrade setuptools
pip install --upgrade pip
gem update --system

echo "Cleaning up ..."
brew cleanup
brew cask cleanup
brew linkapps

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done

echo "Run `mackup restore` after DropBox has done syncing"

read -p "Hit enter to run [OSX for Hackers] script..." c
sh -c "$(curl -sL https://gist.githubusercontent.com/brandonb927/3195465/raw/osx-for-hackers.sh)"
