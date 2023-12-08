#!/usr/bin/env bash

taps=(
  "popcorn-official/popcorn-desktop https://github.com/popcorn-official/popcorn-desktop.git"
)

# See https://sdkman.io/
sdks=(
  "java 8.0.352-amzn"
  "sbt 1.8.3"
  "scala 2.12.18"
)

brews=(
  # Install some stuff before others so we can start settings things up!
  # Software
  authy
  dropbox
  firefox
  google-chrome
  warp
  jetbrains-toolbox
  rectangle
  stats
  spotify
  visual-studio-code
  slack

  # Command line utils
  awscli
  bash
  gimme-aws-creds
  git
  python3

  # Software
  aerial
  adobe-acrobat-pro
  cakebrew
  # cleanmymac   # CI failure
  colima
  dropbox-capture
  expressvpn
  geekbench
  github
  handbrake
  iina
  itsycal
  keepingyouawake
  launchrocket
  little-snitch
  lunar
  macdown
  monitorcontrol
  muzzle
  popcorn-time
  private-eye
  satellite-eyes
  sidekick      # http://oomphalot.com/sidekick/
  sloth         # https://sveinbjorn.org/sloth
  soundsource   # https://rogueamoeba.com/soundsource/
  steam
  "--cask transmission" # This is to install the software and not the CLI

  # Command line tools
  "bash-snippets --without-all-tools --with-cryptocurrency --with-stocks --with-weather"
  bat
  coreutils
  colima
  docker
  docker-compose
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
  mas           # https://github.com/mas-cli/mas
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
  poetry
  streamlit
)

gems=(
  bundler
)

npms=(
  gitjk
  n           # https://github.com/tj/n
  npx
)

# Git configs
gpg_key='3E219504'
git_email='pathikritbhowmick@msn.com'
git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "credential.helper osxkeychain"
  "init.defaultBranch master"
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

fonts=(
  font-fira-code
  font-source-code-pro
)

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
  echo "Completel Homebrew installation and rerun this script ..."
  exit 0
else
  if [[ -z "${CI}" ]]; then
    echo "Updating Homebrew ..."
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Installing SDKs ..."
curl -s "https://get.sdkman.io" | bash
# shellcheck source=/dev/null
source "$HOME/.sdkman/bin/sdkman-init.sh"
for sdk in "${sdks[@]}"
do
  # shellcheck disable=SC2086
  sdk install ${sdk}
done
sdk current
echo "Installing NVM ..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

echo "Installing software ..."
for tap in "${taps[@]}"
do
  # shellcheck disable=SC2086
  brew tap ${tap}
done
install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

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

echo "Setting up bash aliases ..."
echo "
alias del='mv -t ~/.Trash/'
alias ls='exa -l'
alias cat=bat
" >> ~/.bash_profile
# https://github.com/twolfson/sexy-bash-prompt
echo "Setting up bash prompt ..."
# shellcheck source=/dev/null
(cd /tmp && ([[ -d sexy-bash-prompt ]] || git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt) && cd sexy-bash-prompt && make install) && source ~/.bashrc
chsh -s /bin/bash

echo "Installing secondary packages ..."
install 'pip3 install --upgrade' "${pips[@]}"
install 'gem install' "${gems[@]}"
install 'npm install --global --force' "${npms[@]}"

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
