#!/usr/bin/env bash
set -xeuo pipefail

ME="michael" # ADJUST USER NAME
USER_HOME=$(getent passwd "$ME" | cut -d : -f 6)

# link root's bash settings to the same as my user's
rm /root/.profile
rm /root/.bashrc
rm -f /root/.bash_aliases # usually doesn't exist, -f hides failure
ln -s /home/michael/.profile /root/.profile
ln -s /home/michael/.bashrc /root/.bashrc
ln -s /home/michael/.bash_aliases /root/.bash_aliases

apt update
apt -y upgrade

# General Tools
snap install firefox
snap install bitwarden
snap install thunderbird
snap install libreoffice # (or use OnlyOffice)
apt -y install krita
snap install drawio
#apt -y install texlive-full # LaTeX. ~7GB, may downgrade to texlive-latex-extra (~500MB)
apt -y install pandoc # general markup converter (md->pdf: `pandoc file.md -o file.pdf`)
snap install vlc
apt -y install file-roller # Archive Manager (nautilus now supports extraction&compression, but not inspection)
snap install p7zip-desktop
apt -y install pdfchain
apt -y install diffpdf
apt -y install heif-gdk-pixbuf heif-thumbnailer # heif support
# ETH VPN: Cisco Secure Client: manually from https://sslvpn.ethz.ch/+CSCOE+/logon.html?reason=12&gmsg=666768717261672D617267#form_title_text

# Chat
snap install discord
snap install telegram-desktop

# Coding
apt -y install git
snap install code --classic # VS Code
apt -y install python3
apt -y install python3-pip
apt -y install python3.10-venv
apt -y install docker-compose-v2
apt -y install docker-buildx
# use Docker without sudo:
if ! getent group docker > /dev/null 2>&1; then
	groupadd docker
	usermod -aG docker "$ME"
	newgrp docker  # update group membership
fi
# install Node.js and Node Version Manager (nvm) for the user
NVM_DIR="$USER_HOME/.nvm"
sudo -i -u "$ME" bash << EOF
# install Node Version Manager (nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source "$NVM_DIR/nvm.sh"  # load nvm
# install Node.js
nvm install 22
EOF
# Google Chrome: manually from https://www.google.com/chrome/
apt -y install sqlite3
snap install sqlitebrowser

# CLI Tools
# SSH: reconfigure to not hash hosts in `known_hosts`. In `/etc/ssh/ssh_config` set `HashKnownHosts no`.
apt -y install aptitude curl htop lshw
apt -y install net-tools nmap inetutils-traceroute whois
apt -y install iftop nethogs
apt -y install ffmpeg

# install proprietary NVIDIA firmware for nouveau
# https://nouveau.freedesktop.org/VideoAcceleration.html
apt install python2
mkdir /tmp/nouveau
cd /tmp/nouveau
wget https://raw.github.com/envytools/firmware/master/extract_firmware.py
wget http://us.download.nvidia.com/XFree86/Linux-x86/325.15/NVIDIA-Linux-x86-325.15.run
sh NVIDIA-Linux-x86-325.15.run --extract-only
python2 extract_firmware.py
mkdir /lib/firmware/nouveau
cp -d nv* vuc-* /lib/firmware/nouveau/
apt remove python2

echo 'Run `source ~/.profile` to update environment.'

