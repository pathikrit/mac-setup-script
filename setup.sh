#!/usr/bin/env bash

brews=(
  archey
  awscli
  "bash-snippets --without-all-tools --with-cryptocurrency --with-stocks --with-weather"
  #cheat
  coreutils
  dfc
  findutils
  "fontconfig --universal"
  fpp
  git
  git-extras
  git-fresh
  git-lfs
  "gnuplot --with-qt"
  "gnu-sed --with-default-names"
  go
  gpg
  haskell-stack
  hh
  #hosts
  htop
  httpie
  iftop
  "imagemagick --with-webp"
  lighttpd
  lnav
  m-cli
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
  python
  python3
  osquery
  ruby
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
  #volumemixer
  "wget --with-iri"
)

casks=(
  # Install some stuff before others!
  dropbox
  google-chrome
  jetbrains-toolbox
  istat-menus
  java8
  spotify
  #The rest
  adobe-acrobat-reader
  airdroid
  android-platform-tools
  cakebrew
  cleanmymac
  docker
  firefox
  geekbench
  google-backup-and-sync
  github-desktop
  handbrake
  hyper
  iina
  istat-server  
  launchrocket
  kap-beta
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  macdown
  microsoft-office
  muzzle
  path-finder
  plex-media-player
  plex-media-server
  private-eye
  satellite-eyes
  sidekick
  skype
  slack
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

gems=(
  bundler
  travis
)

npms=(
  fenix-cli
  gitjk
  kill-tabs
  n
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
  rust-lang.rust
  dragos.scala-lsp
  lightbend.vscode-sbt-scala
  alanz.vscode-hie-server
  rebornix.Ruby
  redhat.java
)

fonts=(
  font-fira-code
  font-source-code-pro
)

######################################## End of app list ########################################
set +e
#set -x

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}

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
      if [[ ! -z "${CI}" ]]; then
        exit 1
      fi
    fi
  done
}

function brew_install_or_upgrade {
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" > /dev/null); then 
      echo "Upgrading already installed package $1 ..."
      brew upgrade "$1"
    else 
      echo "Latest $1 is already installed"
    fi
  else
    brew install "$1"
  fi
}

if test ! "$(command -v brew)"; then
  prompt "Install Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  if [[ -z "${CI}" ]]; then
    prompt "Update Homebrew"
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

prompt "Install packages"
install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

prompt "Set git defaults"
for config in "${git_configs[@]}"
do
  git config --global ${config}
done
gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}

prompt "Install software"
brew tap caskroom/versions
install 'brew cask install' "${casks[@]}"

prompt "Install secondary packages"
install 'pip3 install --upgrade' "${pips[@]}"
install 'gem install' "${gems[@]}"
install 'npm install --global' "${npms[@]}"
install 'code --install-extension' "${vscode[@]}"
brew tap caskroom/fonts
install 'brew cask install' "${fonts[@]}"

prompt "Upgrade bash"
brew install bash bash-completion2 fzf
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
sudo chsh -s $(brew --prefix)/bin/bash
# Install https://github.com/twolfson/sexy-bash-prompt
(cd /tmp && git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt && cd sexy-bash-prompt && make install) && source ~/.bashrc

prompt "Update packages"
pip3 install --upgrade pip setuptools wheel
mac update

if [[ -z "${CI}" ]]; then
  prompt "Install software from App Store"
  mas list
fi

prompt "Cleanup"
brew cleanup
brew cask cleanup

echo "Run [mackup restore] after DropBox has done syncing ..."
echo "Done!"
