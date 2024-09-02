#!/usr/bin/env bash
set -xeuo pipefail

# link root's bash settings to the same as my user's
rm /root/.profile
rm /root/.bashrc
rm -f /root/.bash_aliases # usually doesn't exist, -f hides failure
ln -s /home/michael/.profile /root/.profile
ln -s /home/michael/.bashrc /root/.bashrc
ln -s /home/michael/.bash_aliases /root/.bash_aliases

apt update
apt upgrade

# General Tools
snap install firefox
snap install bitwarden
snap install thunderbird
snap install libreoffice # (or use OnlyOffice)
snap install krita
snap install xournalpp
snap install drawio
apt install texlive-full # LaTeX. ~7GB, may downgrade to texlive-latex-extra (~500MB)
apt install pandoc # general markup converter (md->pdf: `pandoc file.md -o file.pdf`)
snap install vlc
apt install file-roller # Archive Manager (nautilus now supports extraction&compression, but not inspection)
snap install p7zip-desktop
snap install nextcloud-desktop-client
# ProtonMail Bridge: manually from https://proton.me/mail/bridge
# ETH VPN: Cisco Secure Client: manually from https://sslvpn.ethz.ch/+CSCOE+/logon.html?reason=12&gmsg=666768717261672D617267#form_title_text
snap install okular
apt install pdfchain
apt install diffpdf
apt install gnucash
apt install heif-gdk-pixbuf heif-thumbnailer # heif support
apt install network-manager-strongswan libcharon-extra-plugins # Swisscom VPN (see password manager)

# Duplicati: manually according to https://duplicati.readthedocs.io/en/latest/02-installation/#prerequisites

# Messengers
snap install telegram-desktop
snap install mattermost-desktop
snap install element-desktop
snap install discord
# Zoom: manually from https://zoom.us/download

# Coding
apt install git
snap install code --classic # VS Code
apt install filezilla
# Advanced Rest Client (ARC): manually from https://github.com/advanced-rest-client/arc-electron/releases
apt install sqlite3
snap install sqlitebrowser
apt install phpmyadmin
apt install nodejs # won't give most recent version
apt install npm
npm config set prefix '~/.local' # change setting to avoid permission error (default: `/usr/local`)
npm install -g @angular/cli
# Composer: add `export PATH="$PATH:$HOME/.config/composer/vendor/bin"` to `~/.profile` (instead of what is given in the guide)
apt install composer
# MySQL server. Enable password login.
apt install mysql-server
systemctl disable mysql # only run when we need it
systemctl start mysql
mysql -u root --execute "UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE user = 'root' AND host = 'localhost'; \
    FLUSH PRIVILEGES;"
service mysql restart
mysql -u root --execute "ALTER USER 'root'@'localhost' IDENTIFIED BY 'fy6qBq5jI0BOm0LQ';"
# Linux Valet
# [uninstall instructions](https://cpriego.github.io/valet-linux/#uninstalling)
# _not_ [Valet Linux Plus](https://valetlinux.plus/)
apt install libnss3-tools jq xsel
composer global require cpriego/valet-linux
valet install
# PHP repos
add-apt-repository ppa:ondrej/php
apt update
apt install python3-pip
# TODO: GDB dashboard

# Dev
apt install wireshark
apt install virtualbox

# CLI Tools
# SSH: reconfigure to not hash hosts in `known_hosts`. In `/etc/ssh/ssh_config` set `HashKnownHosts no`.
apt install aptitude curl htop lshw
apt install net-tools nmap inetutils-traceroute whois
apt install iftop nethogs
apt install ffmpeg

