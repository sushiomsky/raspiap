#! /bin/sh
### BEGIN INIT INFO
# Provides:          hotspot.sh
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts captive portal hotspot
# Description:       This file should be used to construct scripts to be
#                    placed in /etc/init.d.
### END INIT INFO

# Author: Foo Bar <foobar@baz.org>
#
# Please remove the "Author" lines above and replace them
# with your own name if you copy and modify this script.

# Do NOT "set -e"

# PATH should only include /usr/* if it runs after the mountnfs.sh script

case "$1" in
  start)
	echo "Starting hotspot services"
	iptables -A POSTROUTING -t nat -o eth0 -j MASQUERADE
	iptables -t mangle -N internet
	iptables -t mangle -A PREROUTING -i wlan1 -p tcp -m tcp --dport 80 -j internet
	iptables -t mangle -A internet -j MARK --set-mark 99
	iptables -t nat -A PREROUTING -i wlan1 -p tcp -m mark --mark 99 -m tcp --dport 80 -j DNAT --to-dest$
	/etc/init.d/apache2 start
	/etc/init.d/hostapd start
	/etc/init.d/udhcpd start
    ;;
  stop)
	echo "Stopping hotspot services"
	/etc/init.d/apache2 stop
        /etc/init.d/hostapd stop
        /etc/init.d/udhcpd stop
	echo "Stopping firewall and allowing everyone..."
	iptables -F
	iptables -X
	iptables -t nat -F
	iptables -t nat -X
	iptables -t mangle -F
	iptables -t mangle -X
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	echo "Bringing interface down"
	ifconfig wlan1 down
    ;;
  *)
    echo "Usage: /etc/init.d/hotspot.sh {start|stop}"
    exit 1
    ;;
esac

exit 0
