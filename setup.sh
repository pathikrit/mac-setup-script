#!/usr/bin/env bash

brews=(
  android-platform-tools
  archey
  aws-shell
  cheat
  coreutils
  dfc             # disk viz
  findutils
  fontconfig --universal
  fpp
  fzf
  git
  git-extras
  git-lfs
  gnuplot --with-qt
  go
  hh
  htop
  httpie
  iftop
  imagemagick
  lighttpd
  lnav
  mackup
  macvim
  mas
  micro
  mtr
  ncdu
  nmap
  node
  poppler
  postgresql
  pgcli
  python
  python3
  osquery
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
  atom
  betterzipql
  cakebrew
  cleanmymac
  commander-one
  datagrip
  docker
  dropbox
  firefox
  geekbench
  google-chrome
  google-drive
  github-desktop
  hosts
  handbrake
  intellij-idea
  istat-menus
  istat-server  
  launchrocket
  licecap
  iterm2
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  macdown
  microsoft-office
  plex-home-theater
  plex-media-server
  private-eye
  satellite-eyes
  sidekick
  skype
  slack
  sling
  spotify
  steam
  teleport
  transmission
  transmission-remote-gui
  tunnelbear
  vlc
  volumemixer
  webstorm
  xquartz
)

pips=(
  pip
  glances
  ohmu
  pythonpy
)

gems=(
  bundle
)

npms=(
  fenix-cli
  gitjk
  kill-tabs
  n
  nuclide-installer
)

gpg_key='3E219504'
git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "core.pager cat"
  "credential.helper osxkeychain"
  "merge.ff false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "rerere.enabled true"
  "user.name pathikrit"
  "user.email pathikritbhowmick@msn.com"
  "user.signingkey ${gpg_key}"
)

apms=(
  atom-beautify
  circle-ci
  ensime
  intellij-idea-keymap
  language-scala
  minimap
)

fonts=(
  font-source-code-pro
)

######################################## End of app list ########################################
set +e
set -x

if test ! $(which brew); then
  echo "Installing Xcode ..."
  xcode-select --install
  
  read -p "Hit enter to continue installing Homebrew ..."

  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
  brew upgrade
fi
brew doctor
brew tap homebrew/dupes

function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    echo "Executing: $exec"
    if $exec ; then
      read -p "Installed $pkg. Hit enter to continue ..."
    else
      read -p "Failed to execute: $exec. Hit enter to continue ..."
    fi
  done
}

echo "Updating ruby ..."
ruby -v
brew install gpg
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
ruby_version='2.6.0'
rvm install ${ruby_version}
rvm use ${ruby_version} --default
ruby -v
sudo gem update --system

echo "Installing Java ..."
brew cask install java

echo "Installing packages ..."
brew info ${brews[@]}
install 'brew install' ${brews[@]}

echo "Tapping casks ..."
brew tap caskroom/fonts
brew tap caskroom/versions

echo "Installing software ..."
brew cask info ${casks[@]}
install 'brew cask install' ${casks[@]}

echo "Installing secondary packages ..."
install 'pip install --upgrade' ${pips[@]}
install 'gem install' ${gems[@]}
install 'npm install --global' ${npms[@]}
install 'apm install' ${apms[@]}
install 'brew cask install' ${fonts[@]}

echo "Upgrading bash ..."
brew install bash
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
mv ~/.bash_profile ~/.bash_profile_backup
mv ~/.bashrc ~/.bashrc_backup
mv ~/.gitconfig ~/.gitconfig_backup
cd; curl -#L https://github.com/barryclark/bashstrap/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,screenshot.png}
source ~/.bash_profile

echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done
gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}

echo "Installing mac CLI ..."
# Note: Say NO to bash-completions since we have fzf!
sh -c "$(curl -fsSL https://raw.githubusercontent.com/guarinogabriel/mac-cli/master/mac-cli/tools/install)"

echo "Updating ..."
pip3 install --upgrade pip setuptools wheel
mac update

echo "Cleaning up ..."
brew cleanup
brew cask cleanup

echo "Run `mackup restore` after DropBox has done syncing"
echo "Done!"
