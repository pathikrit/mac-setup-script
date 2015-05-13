#!/usr/bin/env bash

brews=(
  archey
  bash
  brew-cask
  clib
  coreutils
  dfc
  findutils
  git
  git-extras
  htop
  httpie
  mackup
  macvim
  mtr
  node
  nmap
  postgresql
  pgcli
  python
  ruby
  scala
  sbt
  tmux
  trash
  tree
  wget
  zsh
)

casks=(
  adobe-reader
  airdroid
  asepsis
  atom
  betterzipql
  cakebrew
  chromecast
  cleanmymac
  dropbox
  firefox
  google-chrome
  google-drive
  github
  hosts
  handbrake
  intellij-idea
  istat-menus
  istat-server
  iterm2
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  java
  launchrocket
  plex-home-theater
  plex-media-server
  private-eye
  satellite-eyes
  sidekick
  skype
  slack
  spotify
  steam
  teleport
  transmission
  transmission-remote-gui
  tunnelbear
  vlc
  zeroxdbe-eap
)

pips=(
  Glances
  pythonpy
)

gems=(
  git-up
  bundle
)

npms=(
  coffee-script
  fenix-cli
  gitjk
)

clibs=(
  bpkg/bpkg
)

bkpgs=(
  rauchg/wifi-password
)

git_configs=(
  "rerere.enabled true"
  "branch.autosetuprebase always"
  "credential.helper osxkeychain"
  "user.email pathikritbhowmick@msn.com"
)

apms=(
  circle-ci
  language-scala
)

fonts=(
  font-source-code-pro
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
  brew upgrade brew-cask
fi
brew doctor
brew tap homebrew/dupes

fails=()

function print_red {
  red='\x1B[0;31m'
  NC='\x1B[0m' # no color
  echo -e "${red}$1${NC}"
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
      fails+=($pkg)
      print_red "Failed to execute: $exec"
    fi
  done
}

function proceed_prompt {
  read -p "Proceed with installation? " -n 1 -r
  if [[ $REPLY =~ ^[Nn]$ ]]
  then
    exit 1
  fi
}

brew info ${brews[@]}
proceed_prompt
install 'brew install' ${brews[@]}

brew cask info ${casks[@]}
proceed_prompt
install 'brew cask install --appdir="/Applications"' ${casks[@]}

echo "Tapping casks ..."
brew tap caskroom/fonts
brew tap caskroom/versions

# TODO: add info part of install
install 'pip install' ${pips[@]}
install 'gem install' ${gems[@]}
install 'clib install' ${clibs[@]}
install 'bpkg install' ${bpkgs[@]}
install 'npm install -g' ${npms[@]}
install 'apm install' ${apms[@]}
install 'brew cask install' ${fonts[@]}

echo "Upgrading bash ..."
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"

echo "Setting up zsh ..."
curl -L http://install.ohmyz.sh | sh
chsh -s $(which zsh)
# TODO: Auto-set theme to "fino-time" in ~/.zshrc (using antigen?)
curl -sSL https://get.rvm.io | bash -s stable  # required for some zsh-themes

echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

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
