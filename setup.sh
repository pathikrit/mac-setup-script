#!/usr/bin/env bash

brews=(
  archey
  awscli
  "bash-snippets --without-all-tools --with-weather"
  cheat
  coreutils
  dfc
  findutils
  "fontconfig --universal"
  fpp
  fzf
  git
  bash-completion
  git-extras
  git-fresh
  git-lfs
  "gnuplot --with-qt"
  "gnu-sed --with-default-names"
  go
  haskell-stack
  hh
  htop
  httpie
  iftop
  "imagemagick --with-webp"
  lighttpd
  lnav
  mackup
  macvim
  mas
  micro
  moreutils
  mtr
  ncdu
  nmap
  node
  poppler
  postgresql
  pgcli
  pv
  python3
  osquery
  scala
  sbt
  shellcheck
  stormssh
  teleport
  thefuck
  tmux
  tree
  trash
  "vim --with-override-system-vi"
  "wget --with-iri"
  #hosts
  #volumemixer
)

casks=(
  adobe-acrobat-reader
  airdroid
  android-platform-tools
  cakebrew
  cleanmymac
  commander-one
  docker
  dropbox
  firefox
  geekbench
  google-backup-and-sync
  google-chrome
  github
  handbrake
  hyper
  iina
  istat-menus
  istat-server  
  launchrocket
  licecap
  java8
  jetbrains-toolbox
  kap-beta
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  macdown
  microsoft-office
  muzzle
  plex-media-player
  plex-media-server
  private-eye
  satellite-eyes
  sidekick
  skype
  slack
  spotify
  steam
  transmission
  transmission-remote-gui
  tunnelbear
  visual-studio-code
  xquartz
)

pips=(
  pip
  glances
  ohmu
  pythonpy
)

ruby_version='2.5.0'
gems=(
  bundle
  travis
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

vscode=(
  donjayamanne.python
  dragos.scala-lsp
  lukehoban.Go
  ms-vscode.cpptools
  rebornix.Ruby
  redhat.java
)

fonts=(
  font-source-code-pro
)

######################################## End of app list ########################################
set +e
set -x

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}

if test ! "$(command -v brew)"; then
  prompt "Install Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  prompt "Update Homebrew"
  brew update
  brew upgrade
fi
brew doctor

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    prompt "Execute: $exec"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo "Failed to execute: $exec"
    fi
  done
}

prompt "Update ruby"
ruby -v
brew install gpg
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
rvm install ${ruby_version}
rvm use ${ruby_version} --default
ruby -v
sudo gem update --system

prompt "Install packages"
install 'brew install' "${brews[@]}"

prompt "Install software"
brew tap caskroom/versions
install 'brew cask install' "${casks[@]}"

prompt "Installing secondary packages"
install 'pip install --upgrade' "${pips[@]}"
install 'gem install' "${gems[@]}"
install 'npm install --global' "${npms[@]}"
install 'code --install-extension' "${vscode[@]}"
brew tap caskroom/fonts
install 'brew cask install' "${fonts[@]}"

prompt "Upgrade bash"
brew install bash
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
mv ~/.bash_profile ~/.bash_profile_backup
mv ~/.bashrc ~/.bashrc_backup
mv ~/.gitconfig ~/.gitconfig_backup
cd || exit; curl -#L https://github.com/barryclark/bashstrap/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,screenshot.png}

prompt "Set git defaults"
for config in "${git_configs[@]}"
do
  git config --global "${config}"
done
gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}

if [[ -z "${CI}" ]]; then
  prompt "Install mac CLI [NOTE: Say NO to bash-completions since we have fzf]!"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/guarinogabriel/mac-cli/master/mac-cli/tools/install)"
fi  

prompt "Update packages"
pip3 install --upgrade pip setuptools wheel
mac update

prompt "Cleanup"
brew cleanup
brew cask cleanup

echo "Run [mackup restore] after DropBox has done syncing ..."
echo "Done!"
