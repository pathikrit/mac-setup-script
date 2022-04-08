#!/usr/bin/env bash

# Install some stuff before others!
important_casks=(
  authy
  dropbox
  google-chrome
  hyper
  jetbrains-toolbox
  stats
  spotify
  visual-studio-code
  slack
)

brews=(
  ##### Install these first ######
  xonsh
  jabba
  ################################
  awscli
  "bash-snippets --without-all-tools --with-cryptocurrency --with-stocks --with-weather"
  bat
  #cheat         # https://github.com/cheat/cheat
  coreutils
  dfc           # https://github.com/rolinh/dfc
  exa           # https://the.exa.website/
  findutils
  "fontconfig --universal"
  git
  git-extras    # for git undo
  git-lfs
  "gnuplot --with-qt"
  "gnu-sed --with-default-names"
  go
  gpg
  #hosts
  hstr          # https://github.com/dvorka/hstr
  htop          # https://htop.dev/
  httpie        # https://httpie.io/
  iftop         # https://www.ex-parrot.com/~pdw/iftop/
  "imagemagick --with-webp"
  lnav          # https://lnav.org/
  m-cli         # https://github.com/rgcr/m-cli
  macvim        # https://macvim-dev.github.io/macvim/
  micro         # https://github.com/zyedidia/micro
  mtr           # https://www.bitwizard.nl/mtr/
  neofetch      # https://github.com/dylanaraps/neofetch
  node
  poppler       # https://poppler.freedesktop.org/
  postgresql
  pgcli
  pv            # https://www.ivarch.com/programs/pv.shtml
  python
  python3
  osquery
  ruby
  scala
  sbt
  shellcheck    # https://www.shellcheck.net/
  thefuck       # https://github.com/nvbn/thefuck
  tmux
  tree
  trash
  "vim --with-override-system-vi"
  "wget --with-iri"
  xsv
  youtube-dl
)

casks=(
  aerial
  adobe-acrobat-pro
  cakebrew
  cleanmymac
  docker
  expressvpn
  firefox
  geekbench
  google-backup-and-sync
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
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  satellite-eyes
  sidekick
  sloth
  soundsource
  steam
  synergy
  transmission
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
)

npms=(
  gitjk
  n           # https://github.com/tj/n
)

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
  ms-vsonline.vsonline
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
    #prompt "Execute: $exec"
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

if [[ -z "${CI}" ]]; then
  sudo -v # Ask for the administrator password upfront
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

if test ! "$(command -v brew)"; then
  prompt "Install Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
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
install 'brew cask install' "${important_casks[@]}"

prompt "Install packages"
install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

prompt "Install JDK=${JDK_VERSION}"
curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash && . ~/.jabba/jabba.sh
jabba install ${JDK_VERSION}
jabba alias default ${JDK_VERSION}
java -version

prompt "Set git defaults"
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

if [[ -z "${CI}" ]]; then
  gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}
  prompt "Export key to Github"
  ssh-keygen -t rsa -b 4096 -C ${git_email}
  pbcopy < ~/.ssh/id_rsa.pub
  open https://github.com/settings/ssh/new
fi  

prompt "Upgrade bash"
brew install bash bash-completion2 fzf
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
sudo chsh -s "$(brew --prefix)"/bin/bash
# Install https://github.com/twolfson/sexy-bash-prompt
touch ~/.bash_profile # see https://github.com/twolfson/sexy-bash-prompt/issues/51
(cd /tmp && git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt && cd sexy-bash-prompt && make install) && source ~/.bashrc
hstr --show-configuration >> ~/.bashrc

echo "
alias del='mv -t ~/.Trash/'
alias ls='exa -l'
alias cat=bat
" >> ~/.bash_profile

prompt "Setting up xonsh"
sudo bash -c "which xonsh >> /private/etc/shells"
sudo chsh -s $(which xonsh)
echo "source-bash --overwrite-aliases ~/.bash_profile" >> ~/.xonshrc

prompt "Install software"
install 'brew cask install' "${casks[@]}"

prompt "Install secondary packages"
install 'pip3 install --upgrade' "${pips[@]}"
install 'gem install' "${gems[@]}"
install 'npm install --global' "${npms[@]}"
install 'code --install-extension' "${vscode[@]}"
#brew tap caskroom/fonts
#install 'brew cask install' "${fonts[@]}"

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
