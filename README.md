Práctica Vagrant – Seguridad con iptables

En esta práctica se usa Vagrant para desplegar una  red con varias máquinas virtuales con objetivo de configurar reglas de iptables.





La estructira esta formada por 6 máquinas y 3 redes
Redes

**WAN: 203.0.113.0/24** 

**DMZ: 172.1.6.0/24**

**LAN: 172.2.6.0/24**

Máquins
Gateway (gw) actua como  Router y firewall

- Aplica las reglas de iptables

- Encargado del enrutamiento entre redes

Proxy (DMZ)

Nombre: proxy

IP: 172.1.6.2

Red: DMZ

Accede a servicios externos a través del gateway

Servidor web (DMZ)

Nombre: www

IP: 172.1.6.3

Red: DMZ

Servidor accesible únicamente según las reglas definidas en iptables

Servidor IDP (LAN)

Nombre: idp

IP: 172.2.6.2

Red: LAN

Comunicación controlada hacia la DMZ y WAN

PC administrador (LAN)

Nombre: adminpc

IP: 172.2.6.10

Red: LAN

Equipo de administración con acceso restringido

PC empleado (LAN)

Nombre: empleado

IP: 172.2.6.100

Red: LAN

Equipo de usuario final con permisos limitados



Las reglas de iptables se aplican en la máquina gw y se ejecutan en cada vez zque se arranca el sistema.

El firewall se encarga de:

Permitir el tráfico necesario entre LAN, DMZ y WAN.

Bloquear todo el tráfico no autorizado.

Controlar el acceso a los servicios publicados en la DMZ.

Aplicar políticas de seguridad por defecto.




