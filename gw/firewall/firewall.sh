#!/bin/bash
set -x
# Activar el IP forwarding

sysctl -w net.ipv4.ip_forward=1

# Limpiar reglas previas 
iptables -F
iptables -t nat -F
iptables -Z


# ANTI -LOCK RULES : Permitir ssh de la red de  eth0 para acceder a vagrant
iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 22 -j ACCEPT


# Política por defecto:
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

################################
# Reglas de protección local
################################

#L1. Permitir tráfico de loopback

iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

#L2. Ping a cualquier host
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

#L3. Permitir que me hagan ping desde la LAN Y DMZ
iptables -A INPUT -i eth2 -s 172.1.6.0/24 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i eth3 -s 172.2.6.0/24 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -o eth2 -s 172.1.6.1 -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A OUTPUT -o eth3 -s 172.2.6.1 -p icmp --icmp-type echo-reply -j ACCEPT

#L4. Permitir consultas DNS
iptables -A OUTPUT -o eth0 -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -i eth0 -p udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT


 
################################
# Reglas de protección de red
################################

#### Logs para depurar ####
iptables -A INPUT -j LOG --log-prefix "FRF-INPUT" 
iptables -A OUTPUT -j LOG --log-prefix "FRF-OUTPUT"
iptables -A FORWARD -j LOG --log-prefix "FRF-FORWARD"ls