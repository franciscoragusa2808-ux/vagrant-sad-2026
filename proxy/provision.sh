echo "Limpiando configuracion anterior"
rm -rf /etc/squid/conf.d/*
rm -f /etc/squid/dominios-denegados
rm -f /etc/squid/block-exp

echo "Copiando configuracion desde el proyecto"

# Configuración principal
cp /vagrant/proxy/conf/squid.conf /etc/squid/

# Todos los .conf (lan.conf, debian.conf, dmz.conf…)
cp /vagrant/proxy/conf/*.conf /etc/squid/conf.d/

# Ficheros auxiliares
cp /vagrant/proxy/dominios-denegados /etc/squid/
cp /vagrant/proxy/block-exp /etc/squid/

echo "Reiniciando squid"
systemctl restart squid
