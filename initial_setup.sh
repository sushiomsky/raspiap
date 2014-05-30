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
raspi-config
