#!/usr/bin/env bash

brews=(
  android-platform-tools
  archey
  bash
  brew-cask
  cheat
  clib
  coreutils
  dfc
  findutils
  fpp
  fzf
  git
  git-extras
  go
  gpg
  hh
  htop
  httpie
  iftop
  lighttpd
  lnav
  mackup
  macvim
  mtr
  ncdu
  nmap
  node
  poppler
  postgresql
  pgcli
  python
  python3
  scala
  sbt
  stormssh
  thefuck
  tmux
  tree
  trash
  wget
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
  commander-one
  datagrip
  dockertoolbox
  dropbox
  firefox
  google-chrome
  google-drive
  github-desktop
  hosts
  handbrake
  intellij-idea
  istat-menus
  istat-server
  licecap
  iterm2
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  launchrocket
  microsoft-office
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
  webstorm
)

pips=(
  glances
  ohmu
  pythonpy
)

gems=(
  bundle
)

npms=(
  coffee-script
  fenix-cli
  gitjk
  kill-tabs
  n
  nuclide-installer
  speed-test
  wifi-password
)

clibs=(
  bpkg/bpkg
)

bkpgs=(
)

git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "core.pager ''"
  "credential.helper osxkeychain"
  "merge.ff false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "rerere.enabled true"
  "user.name pathikrit"
  "user.email pathikritbhowmick@msn.com"
)

apms=(
  atom-beautify
  circle-ci
  ensime
  language-scala
  minimap
)

fonts=(
  font-source-code-pro
)

omfs=(
  jacaetevha
  osx
  thefuck
)

######################################## End of app list ########################################
set +e

if test ! $(which brew); then
  echo "Installing Xcode ..."
  xcode-select --install

  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
  brew upgrade
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

echo "Installing ruby ..."
brew install ruby-install chruby
ruby-install ruby
mkdir -p ~/.config/fish/
echo "source /usr/local/share/chruby/chruby.fish" >> ~/.config/fish/config.fish
echo "source /usr/local/share/chruby/auto.fish" >> ~/.config/fish/config.fish
chruby ruby-2.3.0
ruby -v

echo "Installing Java ..."
brew cask install java

brew info ${brews[@]}
proceed_prompt
install 'brew install' ${brews[@]}

echo "Tapping casks ..."
brew tap caskroom/fonts
brew tap caskroom/versions

brew cask info ${casks[@]}
proceed_prompt
install 'brew cask install --appdir=/Applications' ${casks[@]}

# TODO: add info part of install or do reinstall?
install 'pip install --upgrade' ${pips[@]}
install 'gem install' ${gems[@]}
install 'clib install' ${clibs[@]}
install 'bpkg install' ${bpkgs[@]}
install 'npm install --global' ${npms[@]}
install 'apm install' ${apms[@]}
install 'brew cask install' ${fonts[@]}

echo "Upgrading bash ..."
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"

echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done
git alias rpush '! git up && git push'

echo "Setting up go ..."
mkdir -p /usr/libs/go
echo "export GOPATH=/usr/libs/go" >> ~/.config/fish/config.fish
echo "export PATH=$PATH:$GOPATH/bin" >> ~/.config/fish/config.fish

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

echo "Setting up fish shell ..."
brew install fish chruby-fish
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)
curl -L https://github.com/oh-my-fish/oh-my-fish/raw/master/bin/install | fish
install 'omf install' ${omfs[@]}

echo "Done!"
