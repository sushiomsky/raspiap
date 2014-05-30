#!/bin/bash
apt-get update; apt-get -y upgrade; apt-get -y dist-upgrade
dpkg-reconfigure tzdata
dpkg-reconfigure console-data
dpkg-reconfigure locales
apt-get -y install ca-certificates
apt-get -y install git-core curl build-essential sudo



echo "deb http://archive.raspberrypi.org/debian/ wheezy main" >> /etc/apt/sources.list
wget http://archive.raspberrypi.org/debian/raspberrypi.gpg.key
apt-key add raspberrypi.gpg.key
apt-get update
apt-get -y install raspi-config

wget https://raw.github.com/Hexxeh/rpi-update/master/rpi-update -O /usr/bin/rpi-update && sudo chmod +x /usr/bin/rpi-update 

wget https://raw.githubusercontent.com/notro/rpi-source/master/rpi-source -O /usr/bin/rpi-source && sudo chmod +x /usr/bin/rpi-source && /usr/bin/rpi-source -q --tag-update
