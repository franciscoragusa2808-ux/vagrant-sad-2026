#!/bin/bash
set -ex

# Activar IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Limpiar reglas previas
iptables -F
iptables -t nat -F
iptables -Z
iptables -t nat -Z

# ANTI-LOCK rule: Permitir ssh através de ETH0 para acceder con vagrant
iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 22 -j ACCEPT

iptables -A INPUT -i eth1 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -o eth1 -p icmp --icmp-type echo-reply -j ACCEPT

# POLÍTICAS POR DEFECTO
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

###########################
# Reglas de protección local
###########################

# L1. Loopback
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT 

# L2. Ping saliente
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

# L3. Permitir ping desde LAN y DMZ
iptables -A INPUT -i eth2 -s 172.1.6.0/24 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i eth3 -s 172.2.6.0/24 -p icmp --icmp-type echo-request -j ACCEPT

iptables -A OUTPUT -o eth2 -s 172.1.6.1 -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A OUTPUT -o eth3 -s 172.2.6.1 -p icmp --icmp-type echo-reply -j ACCEPT

# L4. DNS
iptables -A OUTPUT -o eth0 -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -i eth0 -p udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# L5. HTTP/HTTPS
iptables -A OUTPUT -o eth0 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A OUTPUT -o eth0 -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# L6. SSH adminpc
iptables -A INPUT -i eth3 -s 172.2.6.10 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth3 -d 172.2.6.10 -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


############################
# Reglas de red
############################

# R1. NAT LAN
iptables -t nat -A POSTROUTING -s 172.2.6.0/24 -o eth0 -j MASQUERADE

# R3.A LAN → WWW DMZ
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.6.0/24 -d 172.1.6.3 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.6.3 -d 172.2.6.0/24 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# R2. WAN → WWW
iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 80 -j DNAT --to-destination 172.1.6.3:80
iptables -A FORWARD -i eth1 -o eth2 -d 172.1.6.3 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -s 172.1.6.3 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# R3.B SSH LAN → DMZ
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.6.10 -d 172.1.6.0/24 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.6.0/24 -d 172.2.6.10 -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Proxy LAN
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.6.0/24 -d 172.1.6.2 -p tcp --dport 3128 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.6.2 -d 172.2.6.0/24 -p tcp --sport 3128 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# DNS LAN
iptables -A FORWARD -i eth3 -o eth0 -s 172.2.6.0/24 -p udp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -d 172.2.6.0/24 -p udp --sport 53 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# NTP LAN
iptables -A FORWARD -i eth3 -o eth0 -s 172.2.6.0/24 -p udp --dport 123 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -d 172.2.6.0/24 -p udp --sport 123 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# NAT DMZ
iptables -t nat -A POSTROUTING -s 172.1.6.0/24 -o eth0 -j MASQUERADE

# LDAP
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.6.0/24 -d 172.2.6.2 -p tcp --dport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.6.2 -d 172.1.6.0/24 -p tcp --sport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# VPN WAN
iptables -A INPUT -i eth1 -p udp --dport 1194 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth1 -p udp --sport 1194 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# VPN → DMZ
iptables -A FORWARD -i tun0 -o eth2 -s 172.3.6.0/24 -d 172.1.6.3 -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o tun0 -s 172.1.6.3 -d 172.3.6.0/24 -p tcp -m multiport --sports 80,443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# VPN → LDAP
iptables -A FORWARD -i tun0 -o eth3 -s 172.3.6.0/24 -d 172.2.6.2 -p tcp --dport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth3 -o tun0 -s 172.2.6.2 -d 172.3.6.0/24 -p tcp --sport 389 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Ping VPN
iptables -A FORWARD -i tun0 -p icmp -j ACCEPT
iptables -A FORWARD -o tun0 -p icmp -j ACCEPT

######## Logs
iptables -A INPUT -j LOG --log-prefix "FRF-INPUT: "
iptables -A OUTPUT -j LOG --log-prefix "FRF-OUTPUT: "
iptables -A FORWARD -j LOG --log-prefix "FRF-FORWARD: "
