#!/usr/bin/env bash

brews=(
  # Install some stuff before others so we can start settings things up!
  
  # Software
  dropbox
  firefox
  google-chrome
  rectangle
  stats
  spotify
  visual-studio-code

  # AI
  claude-code
  codex
  orca

  # Programming Languages
  bash
  python3
  node
  nvm  
  python
  ruby    

  # Git
  git
  gh
  git-lfs

  # Software
  adobe-acrobat-pro
  expressvpn
  iina
  itsycal
  lunar
  monitorcontrol
  muzzle
  private-eye
  satellite-eyes
  docker
  docker-compose
  
  # Command line tools
  coreutils  
  findutils
  "fontconfig --universal"      
  "gnu-sed --with-default-names"
  gpg  
  "imagemagick --with-webp"
  tmux  
  "vim --with-override-system-vi"
  "wget --with-iri"  
)

pips=(
  pip  
  uv
  streamlit
)

gems=(
  bundler
)

npms=(
  npx
)

# Git configs
gpg_key='3E219504'
git_email='pathikritbhowmick@msn.com'
# See https://jvns.ca/blog/2024/02/16/popular-git-config-options/
# and https://blog.gitbutler.com/how-git-core-devs-configure-git/
git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "core.pager delta"
  "credential.helper osxkeychain"
  "diff.algorithm histogram"
  "fetch.prune true"
  "help.autocorrect 10"
  "init.defaultBranch master"
  "merge.ff false"
  "merge.conflictstyle zdiff3"
  "pull.rebase true"
  "push.default simple"
  "push.autoSetupRemote true"
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

######################################## Start Installing ########################################

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
install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

echo "Setting up git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global "${config}"
done

echo "Setting up bash aliases ..."
cat >> ~/.bashrc << 'EOF'

alias del='mv -t ~/.Trash/'
alias ls='exa -l'
alias cat=bat
alias gmaster='git fetch origin && git checkout $(git rev-parse --abbrev-ref origin/HEAD | sed "s|origin/||") && git merge --ff-only @{u}'
EOF
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

if [[ -z "${CI}" ]]; then
  echo "Export key to Github ..."
  gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}
  ssh-keygen -t rsa -b 4096 -C ${git_email}
  pbcopy < ~/.ssh/id_rsa.pub
  open https://github.com/settings/ssh/new
fi

echo "Cleanup"
brew cleanup

echo "Done!"
