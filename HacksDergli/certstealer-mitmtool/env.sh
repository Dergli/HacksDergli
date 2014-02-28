#!/bin/bash
printf "Site to Proxy: "
read victim
sudo hostname $victim
sudo hostname -b $victim
sudo resolvconf -u
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 4433 -j REDIRECT --to-port 443
sudo iptables -t nat -A PREROUTING -i eth0 -p udp --dport 443 -j REDIRECT --to-port 4433
echo 127.0.0.1 $victim >> /etc/hosts

