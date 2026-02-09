#!/usr/bin/env bash

set -e
export DEBIAN_FRONTEND=noninteractive

echo "########################################"
echo " Aprovisionando proxy"
echo "########################################"

echo "Actualizando repositorios"
apt-get update -y

echo "Instalando squid"
apt-get install -y squid

echo "Creando estructura de directorios"
mkdir -p /etc/squid/conf.d

echo "Limpiando configuracion anterior"
rm -rf /etc/squid/conf.d/*
rm -f /etc/squid/dominios-denegados
rm -f /etc/squid/block-exp

echo "Copiando configuracion desde el proyecto"

cp /vagrant/proxy/conf/squid.conf /etc/squid/
cp /vagrant/proxy/conf/*.conf /etc/squid/conf.d/
cp /vagrant/proxy/dominios-denegados /etc/squid/
cp /vagrant/proxy/block-exp /etc/squid/

echo "Reiniciando squid"
systemctl enable squid
systemctl restart squid

echo "------ FIN PROXY ------"
su