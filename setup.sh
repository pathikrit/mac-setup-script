#!/usr/bin/env bash

brews=(
  archey
  bash
  brew-cask
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
  mackup
  macvim
  mtr
  ncdu
  nmap
  node
  postgresql
  pgcli
  python
  python3
  ruby
  rbenv
  ruby-build
  scala
  sbt
  stormssh
  thefuck
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
  commander-one
  dockertoolbox
  dropbox
  firefox
  google-chrome
  google-drive
  github
  gitter
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
  java
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
  zeroxdbe-eap
)

pips=(
  glances
  ohmu
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
  speed-test
  kill-tabs
  wifi-password
)

clibs=(
  bpkg/bpkg
)

bkpgs=(
)

git_configs=(
  "rerere.enabled true"
  "branch.autosetuprebase always"
  "credential.helper osxkeychain"
  "rebase.autostash true"
  "user.email pathikritbhowmick@msn.com"
)

apms=(
  atom-beautify
  autocomplete-plus
  circle-ci
  markdown-preview
  minimap
  nuclide-installer
  language-coffee-script
  language-gfm
  language-html
  language-java
  language-javascript
  language-json
  language-python
  language-scala
  language-shellscript
  language-sql
  language-xml
  language-yaml
)

fonts=(
  font-source-code-pro
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

brew info ${brews[@]}
proceed_prompt
install 'brew install' ${brews[@]}

echo "Upgrading ruby ..."
curl -sSL https://get.rvm.io | bash -s stable
rvm autolibs homebrew
rvm requirements
echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.zshrc
rbenv install 2.2.3
rbenv global 2.2.3
ruby -v

echo "Tapping casks ..."
brew tap caskroom/fonts
brew tap caskroom/versions

brew cask info ${casks[@]}
proceed_prompt
install 'brew cask install --appdir="/Applications"' ${casks[@]}

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

echo "Setting up zsh ..."
curl -L http://install.ohmyz.sh | sh
chsh -s $(which zsh)
# TODO: Auto-set theme to "re5et" in ~/.zshrc (using antigen?)

echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

echo "Setting up go ..."
mkdir -p /usr/libs/go
echo "export GOPATH=/usr/libs/go" >> ~/.zshrc
echo "export PATH=$PATH:$GOPATH/bin" >> ~/.zshrc

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
