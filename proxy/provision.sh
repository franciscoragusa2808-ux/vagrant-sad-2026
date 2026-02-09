#!/usr/bin/env bash

set -e
export DEBIAN_FRONTEND=noninteractive

echo "Actualizando sistema"
apt-get update -y

echo "Instalando squid y helpers ldap"
apt-get install -y squid squid-common ldap-utils

echo "Creando estructura de directorios"
mkdir -p /etc/squid/conf.d

echo "Limpiando configuracion anterior"
rm -f /etc/squid/conf.d/lan.conf
rm -f /etc/squid/conf.d/dmz.conf
rm -f /etc/squid/dominios-denegados
rm -f /etc/squid/block-exp

echo "Copiando configuracion principal"
cp /vagrant/proxy/conf/squid.conf /etc/squid/squid.conf

echo "Copiando configuraciones adicionales"
cp /vagrant/proxy/conf/lan.conf /etc/squid/conf.d/
cp /vagrant/proxy/conf/dmz.conf /etc/squid/conf.d/

echo "Copiando listas"
cp /vagrant/proxy/dominios-denegados /etc/squid/
cp /vagrant/proxy/block-exp /etc/squid/

echo "Reiniciando squid"
systemctl restart squid

echo "------ FIN PROXY ------"
