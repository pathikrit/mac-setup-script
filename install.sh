#!/usr/bin/env bash

# Install some stuff before others!
important_casks=(
  firefox
  google-chrome
  iterm2
  jetbrains-toolbox
  slack
  visual-studio-code
)

brews=(
  ##### Install these first ######
  # awscli
  bash
  circleci
  git
  github/gh/gh
  python3
  sbt  
  scala
  ################################
  coreutils
  #hosts
  "imagemagick --with-webp"
  macvim        # https://macvim-dev.github.io/macvim/
  node
  python 
  reattach-to-user-namespace # this enables copy/paste for vi within tmux
  tmux
  tree
  # "vim --with-override-system-vi"
  "wget --with-iri"
)

casks=(
  cakebrew
  calibre
  discord
  itsycal
  cleanmymac
  steam
  spectacle
)

pips=(
  pip
)

gems=(
  bundler
)

npms=(
  gitjk
  n           # https://github.com/tj/n
)

git_email='will.chiong@gmail.com'
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
  "user.name Will Chiong"
  "user.email ${git_email}"
)

vscode=(
  scalameta.metals
  scala-lang.scala
)

fonts=(
  font-fira-code
  font-jetbrains-mono
  font-source-code-pro
)

######################################## End of app list ########################################
set +e
set -x

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p -r "Hit Enter to $1 ..."
  fi
}

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    #prompt "Execute: $exec"
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
  prompt "Install Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  if [[ -z "${CI}" ]]; then
    prompt "Update Homebrew"
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Install important software ..."
brew tap homebrew/cask-versions
install 'brew install --cask' "${important_casks[@]}"

prompt "Install packages"
install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

prompt "Set git defaults"
for config in "${git_configs[@]}"
do
  git config --global "${config}"
done

if [[ -z "${CI}" ]]; then
  # gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}
  prompt "Export key to Github"
  ssh-keygen -t rsa -b 4096 -C ${git_email}
  pbcopy < ~/.ssh/id_rsa.pub
  open https://github.com/settings/ssh/new
fi  

prompt "Upgrade bash"
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
sudo chsh -s "$(brew --prefix)"/bin/bash

prompt "Install software"
install 'brew install --cask' "${casks[@]}"

prompt "Install secondary packages"
install 'pip3 install --upgrade' "${pips[@]}"
install 'gem install' "${gems[@]}"
install 'npm install --global' "${npms[@]}"
install 'code --install-extension' "${vscode[@]}"
brew tap homebrew/cask-fonts
install 'brew install --cask' "${fonts[@]}"

prompt "Update packages"
pip3 install --upgrade pip setuptools wheel
if [[ -z "${CI}" ]]; then
  m update install all
fi

if [[ -z "${CI}" ]]; then
  prompt "Install software from App Store"
  mas list
fi

prompt "Cleanup"
brew cleanup

echo "Done!"
