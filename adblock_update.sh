#!/bin/bash

cd /tmp
wget http://winhelp2002.mvps.org/hosts.txt
rm /etc/hosts
mv hosts.txt /etc/hosts
cat /root/.etchosts >> /etc/hosts


