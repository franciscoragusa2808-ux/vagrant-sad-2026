echo "Limpiando configuracion anterior"
rm -rf /etc/squid/conf.d/*
rm -f /etc/squid/dominios-denegados
rm -f /etc/squid/block-exp

echo "Copiando configuracion desde el proyecto"

cp /vagrant/proxy/conf/squid.conf /etc/squid/
cp /vagrant/proxy/conf/lan.conf /etc/squid/conf.d/
cp /vagrant/proxy/conf/debian.conf /etc/squid/conf.d/

cp /vagrant/proxy/dominios-denegados /etc/squid/
cp /vagrant/proxy/block-exp /etc/squid/

echo "Reiniciando squid"
systemctl restart squid
