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

################################
# Reglas de protección de red
################################

#### Logs para depurar ####
iptables -A INPUT -j LOG --log-prefix "FRF-INPUT" 
iptables -A OUTPUT -j LOG --log-prefix "FRF-OUTPUT"
iptables -A FORWARD -j LOG --log-prefix "FRF-FORWARD"