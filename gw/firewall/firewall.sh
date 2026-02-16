#!/bin/bash
set -x

# Activar IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Limpiar reglas previas
iptables -F
iptables -t nat -F
iptables -Z

# Política por defecto
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

################################
# ANTI-LOCK (SSH desde WAN)
################################
iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 22 -j ACCEPT

################################
# PROTECCIÓN LOCAL
################################

# Loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Ping saliente
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
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

#L5. Permitir HTTP/HTTPS PARA actualizar y nevegar
iptables -A OUTPUT -o eth0 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#L.5 Permitir acceso ssh para admincpc
iptables -A INPUT -i eth3 -s 172.2.6.10 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth3 -s 172.2.6.10 -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

################################
# R1. NAT
################################
iptables -t nat -A POSTROUTING -s 172.2.6.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.1.6.0/24 -o eth0 -j MASQUERADE

################################
# R2. WAN → WWW (DMZ)
################################
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 172.1.6.3:80
iptables -A FORWARD -i eth0 -o eth2 -d 172.1.6.3 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -s 172.1.6.3 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

################################
# R4.v2. LAN debe salir por el proxy
################################

# LAN → Proxy
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.6.0/24 -d 172.1.6.2 -p tcp --dport 3128 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -d 172.2.6.0/24 -s 172.1.6.2 -p tcp --sport 3128 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# LAN DNS directo
iptables -A FORWARD -i eth3 -o eth0 -s 172.2.6.0/24 -p udp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -d 172.2.6.0/24 -p udp --sport 53 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# LAN NTP
iptables -A FORWARD -i eth3 -o eth0 -s 172.2.6.0/24 -p udp --dport 123 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -d 172.2.6.0/24 -p udp --sport 123 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

################################
# R5.v2. DMZ debe salir SOLO por el proxy
################################

# DMZ → Proxy (misma interfaz eth2)
iptables -A FORWARD -i eth2 -o eth2 -s 172.1.6.0/24 -d 172.1.6.2 -p tcp --dport 3128 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth2 -d 172.1.6.0/24 -s 172.1.6.2 -p tcp --sport 3128 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

################################
# P6. Proxy → Internet (80,443)
################################
iptables -A FORWARD -i eth2 -o eth0 -s 172.1.6.2 -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -d 172.1.6.2 -p tcp -m multiport --sports 80,443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

################################
# P4. LDAP desde DMZ
################################
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.6.0/24 -d 172.2.6.2 -p tcp --dport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.6.2 -d 172.1.6.0/24 -p tcp --sport 389 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Regla P4.2.1 Permitir acceso WAN (eth1) a servidor VPN
iptables -A INPUT -i eth1 -p udp --dport 1194 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth1 -p udp --sport 1194 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permitir que openvpn en el GW consulte al servidor LDAP
iptables -A OUTPUT -o eth3 -d 172.2.6.2 -p tcp --sport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth3 -s 172.2.6.2 -p tcp --sport 389 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Regla P4.2.2 Permitir acceso de VPN-net a http de la DMZ
iptables -A FORWARD -i tun0 -o eth2 -s 172.3.6.0/24 -d 172.1.6.3 -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o tun0 -s 172.1.6.3 -d 172.3.6.0/24 -p tcp -m multiport --sports 80,443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Regla P4.2.3 Permitir acceso de VPN-net a IDP de la DMZ
iptables -A FORWARD -i tun0 -o eth3 -s 172.3.6.0/24 -d 172.2.6.2 -p tcp --dport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth3 -o tun0 -s 172.2.6.2 -d 172.3.6.0/24 -p tcp --sport 389 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


################################
# LOGS
################################
iptables -A INPUT -j LOG --log-prefix "FRF-INPUT "
iptables -A OUTPUT -j LOG --log-prefix "FRF-OUTPUT "
iptables -A FORWARD -j LOG --log-prefix "FRF-FORWARD "
