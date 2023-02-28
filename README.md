[![CI](https://github.com/pathikrit/mac-setup-script/actions/workflows/ci.yml/badge.svg)](https://github.com/pathikrit/mac-setup-script/actions/workflows/ci.yml)

Dead simple script to setup my new Mac:
```shell
cd ~/Downloads
curl -sL https://raw.githubusercontent.com/pathikrit/mac-setup-script/master/defaults.sh | bash
curl -O https://raw.githubusercontent.com/pathikrit/mac-setup-script/master/install.sh
chmod +x install.sh
./install.sh > install_log.txt
```
