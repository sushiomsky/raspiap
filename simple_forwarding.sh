#!/bin/bash
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "Starting IP forwarding and traffic shaping\n"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

#Traffic shaping
tc qdisc add dev wlan0 root handle 1:0 htb default 10
tc class add dev wlan0 parent 1:0 classid 1:10 htb rate 256kbps ceil 256kbps prio 0

tc class add dev wlan0 parent 1:1 classid 1:5 htb rate 512kbps ceil 512kbps prio 1
tc filter add dev wlan0 parent 1:0 prio 1 handle 5 fw flowid 1:5

iptables -t mangle -N shaper-out
iptables -t mangle -N shaper-in


iptables -t mangle -I POSTROUTING -o wlan0 -j shaper-in
iptables -t mangle -I PREROUTING -i wlan0 -j shaper-out
iptables -t mangle -I PREROUTING -i eth0 -j shaper-in
iptables -t mangle -I POSTROUTING -o eth0 -j shaper-out


iptables -t mangle -A shaper-out -s 192.168.3.0/24 -j MARK --set-mark 1
iptables -t mangle -A shaper-in -d 192.168.3.0/24 -j MARK --set-mark 1

iptables -t mangle -A shaper-out -s 192.168.3.2 -j MARK --set-mark 5
iptables -t mangle -A shaper-in -d 192.168.3.2 -j MARK --set-mark 5


