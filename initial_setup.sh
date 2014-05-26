#!/bin/bash
apt-get update; apt-get -y upgrade; apt-get -y dist-upgrade
dpkg-reconfigure tzdata
dpkg-reconfigure console-data
dpkg-reconfigure locales
apt-get -y install ca-certificates
apt-get -y install wireless-tools
apt-get -y install git-core curl
#sudo curl -L --output /usr/bin/rpi-update https://raw.github.com/Hexxeh/rpi-update/master/rpi-update && sudo chmod +x /usr/bin/rpi-update
#rpi-update

cd /usr/local/src
git clone https://github.com/sushiomsky/raspiap
cd raspiap
#cp raspi-config/raspi-config /usr/bin



echo "deb http://archive.raspberrypi.org/debian/ wheezy main" >> /etc/apt/sources.list
wget http://archive.raspberrypi.org/debian/raspberrypi.gpg.key
apt-key add raspberrypi.gpg.key
apt-get update
apt-get -y install raspi-config
raspi-config


apt-get -y install parted
# rpi-wiggle
mkdir -p /root/scripts
wget https://raw.github.com/dweeber/rpiwiggle/master/rpi-wiggle -O /root/scripts/rpi-wiggle.sh
chmod 755 /root/scripts/rpi-wiggle.sh

swapoff -a
parted  /dev/mmcblk0 --script rm 3 
/root/scripts/rpi-wiggle.sh


