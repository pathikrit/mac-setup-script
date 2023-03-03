#!/usr/bin/env bash

brews=(
  # Install some stuff before others so we can start settings things up!
  # Software
  authy
  dropbox
  firefox
  google-chrome
  hyper
  jetbrains-toolbox
  stats
  spotify
  visual-studio-code
  slack

  # Command line utils
  awscli
  gimme-aws-creds
  git
  jabba
  python3
  sbt
  scala
  xonsh

  # Software
  aerial
  adobe-acrobat-pro
  cakebrew
#BUILD FAILURE  cleanmymac
  colima
  docker 
  docker-compose
  expressvpn
  geekbench
  github
  handbrake
  iina
  istat-server
  kap
  keepingyouawake
  launchrocket
  little-snitch
  macdown
  monitorcontrol
  muzzle
  private-eye
  satellite-eyes
  sidekick      # http://oomphalot.com/sidekick/
  sloth         # https://sveinbjorn.org/sloth
  soundsource   # https://rogueamoeba.com/soundsource/
  steam
  transmission

  # Command line tools
  "bash-snippets --without-all-tools --with-cryptocurrency --with-stocks --with-weather"
  bat
  coreutils
  dfc           # https://github.com/rolinh/dfc
  exa           # https://the.exa.website/
  findutils
  "fontconfig --universal"
  git-extras    # for git undo
  git-lfs
  "gnuplot --with-qt"
  "gnu-sed --with-default-names"
  go
  gpg
  hstr          # https://github.com/dvorka/hstr
  htop          # https://htop.dev/
  httpie        # https://httpie.io/
  iftop         # https://www.ex-parrot.com/~pdw/iftop/
  "imagemagick --with-webp"
  lnav          # https://lnav.org/
  m-cli         # https://github.com/rgcr/m-cli
  micro         # https://github.com/zyedidia/micro
  mtr           # https://www.bitwizard.nl/mtr/
  neofetch      # https://github.com/dylanaraps/neofetch
  node
  poppler       # https://poppler.freedesktop.org/
  postgresql
  pgcli
  pv            # https://www.ivarch.com/programs/pv.shtml
  python 
  osquery
  ruby
  shellcheck    # https://www.shellcheck.net/
  thefuck       # https://github.com/nvbn/thefuck
  tmux
  tree
  trash
  "vim --with-override-system-vi"
  "wget --with-iri"
  xquartz
  xsv
  yarn
  youtube-dl
)

pips=(
  pip
  glances
  ohmu
  pythonpy
)

gems=(
  bundler
)

npms=(
  gitjk
  n           # https://github.com/tj/n
)

# Git configs
gpg_key='3E219504'
git_email='pathikritbhowmick@msn.com'
git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "credential.helper osxkeychain"
  "merge.ff false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "remote.origin.prune true"
  "rerere.enabled true"
  "user.name pathikrit"
  "user.email ${git_email}"
  "user.signingkey ${gpg_key}"
)

vscode=(
  alanz.vscode-hie-server
  justusadam.language-haskell
  ms-ossdata.vscode-postgresql
  rebornix.ruby
  redhat.java
  rust-lang.rust
  scalameta.metals
  scala-lang.scala
)

fonts=(
  font-fira-code
  font-source-code-pro
)

JDK_VERSION=amazon-corretto@1.8.222-10.1

######################################## End of app list ########################################
set +e
set -x

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo "Failed to execute: $exec"
      if [[ -n "${CI}" ]]; then
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

if [[ -z "${CI}" ]]; then
  sudo -v # Ask for the administrator password upfront
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

if test ! "$(command -v brew)"; then
  echo "Installing Homebrew ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
  if [[ -z "${CI}" ]]; then
    echo "Updating Homebrew ..."
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Installing software ..."
install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

echo "Installing JDK=${JDK_VERSION} ..."
jabba install ${JDK_VERSION}
jabba alias default ${JDK_VERSION}
java -version

echo "Setting up git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global "${config}"
done

if [[ -z "${CI}" ]]; then
  gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}
  echo "Export key to Github"
  ssh-keygen -t rsa -b 4096 -C ${git_email}
  pbcopy < ~/.ssh/id_rsa.pub
  open https://github.com/settings/ssh/new
fi  

echo "Upgrading bash ..."
brew install bash bash-completion2 fzf
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
sudo chsh -s "$(brew --prefix)"/bin/bash
# Install https://github.com/twolfson/sexy-bash-prompt
touch ~/.bash_profile # see https://github.com/twolfson/sexy-bash-prompt/issues/51
# shellcheck source=/dev/null
(cd /tmp && git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt && cd sexy-bash-prompt && make install) && source ~/.bashrc
hstr --show-configuration >> ~/.bashrc
echo "
alias del='mv -t ~/.Trash/'
alias ls='exa -l'
alias cat=bat
" >> ~/.bash_profile

echo "Setting up xonsh ..."
sudo bash -c "which xonsh >> /private/etc/shells"
sudo chsh -s "$(which xonsh)"
echo "source-bash --overwrite-aliases ~/.bash_profile" >> ~/.xonshrc

echo "Installing secondary packages ..."
install 'pip3 install --upgrade' "${pips[@]}"
install 'gem install' "${gems[@]}"
install 'npm install --global' "${npms[@]}"
install 'code --install-extension' "${vscode[@]}"

echo "Installing fonts ..."
brew tap homebrew/cask-fonts
install 'brew install' "${fonts[@]}"

echo "Updating packages ..."
pip3 install --upgrade pip setuptools wheel
if [[ -z "${CI}" ]]; then
  m update install all
fi

if [[ -z "${CI}" ]]; then
  echo "Install following software from the App Store"
  mas list
fi

echo "Cleanup"
brew cleanup

echo "Done!"
