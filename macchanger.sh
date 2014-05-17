#!/bin/bash
/etc/init.d/dnsmasq stop
/etc/init.d/hostapd stop

# Disable the network devices
ifconfig wlan0 down

# Spoof the mac addresses
/usr/bin/macchanger -r wlan0

# Re-enable the devices
ifconfig wlan0 up
/etc/init.d/dnsmasq start
/etc/init.d/hostapd start

