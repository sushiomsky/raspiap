#!/bin/bash
apt-get update; apt-get -y upgrade; apt-get -y dist-upgrade
dpkg-reconfigure tzdata
dpkg-reconfigure console-data
dpkg-reconfigure locales
apt-get -y install ca-certificates
apt-get -y install git-core curl build-essential sudo ffmpeg sox libsox-fmt-all autoconf automake cmake build-essential curl git-core mpd hostapd inadyn sslstrip mitmproxy aircrack-ng nmap ethtool wpasupplicant subversion usbutils 


#PiFm & PiFmplay
cd /usr/local/src/
git clone https://github.com/rm-hull/pifm pifm
cd pifm
g++ -O3 -o pifm pifm.c
chmod +x pifm
cd /usr/local/sbin/
ln -s /usr/local/src/pifm/pifm pifm

cd /usr/local/src/
git clone https://github.com/Mikael-Jakhelln/PiFMPlay pifmplay
cd /usr/local/sbin/
ln -s /usr/local/src/pifm/pifmplay pifmplay

#OPenWifi Autoconnect
cd /usr/local/bin/
wget http://true-random.com/homepage/projects/wifi/freewifi_autoconnect.sh
chmod +x freewifi_autoconnect.sh

#sslstrip credential extractor
git clone https://github.com/sushiomsky/logex


echo "deb http://archive.raspberrypi.org/debian/ wheezy main" >> /etc/apt/sources.list
wget http://archive.raspberrypi.org/debian/raspberrypi.gpg.key
apt-key add raspberrypi.gpg.key
apt-get update
apt-get -y install raspi-config

wget https://raw.github.com/Hexxeh/rpi-update/master/rpi-update -O /usr/bin/rpi-update && sudo chmod +x /usr/bin/rpi-update 

wget https://raw.githubusercontent.com/notro/rpi-source/master/rpi-source -O /usr/bin/rpi-source && sudo chmod +x /usr/bin/rpi-source && /usr/bin/rpi-source -q --tag-update
