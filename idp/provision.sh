#!/usr/bin/env bash

set -e
export DEBIAN_FRONTEND=noninteractive

echo "########################################"
echo " Aprovisionando IDP (OpenLDAP)"
echo "########################################"

echo "Actualizando sistema"
apt-get update -y

echo "Instalando OpenLDAP y utilidades"
apt-get install -y slapd ldap-utils

echo "Configurando slapd (modo no interactivo)"
debconf-set-selections <<EOF
slapd slapd/no_configuration boolean false
slapd slapd/domain string fragflo159.org
slapd shared/organization string fragflo159
slapd slapd/password1 password asir
slapd slapd/password2 password asir
slapd slapd/backend select MDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
EOF

dpkg-reconfigure -f noninteractive slapd

echo "Esperando a que LDAP esté disponible"
sleep 5

echo "Cargando estructura base LDAP"
ldapadd -x -D "cn=admin,dc=fragflo159,dc=org" -w asir -f /vagrant/idp/sldapdb/base.ldif || true

echo "Cargando grupos LDAP"
ldapadd -x -D "cn=admin,dc=fragflo159,dc=org" -w asir -f /vagrant/idp/sldapdb/grupos.ldif || true

echo "Cargando usuarios LDAP"
ldapadd -x -D "cn=admin,dc=fragflo159,dc=org" -w asir -f /vagrant/idp/sldapdb/usuarios.ldif || true

echo "Cargando grupo proxy_users"
ldapadd -x -D "cn=admin,dc=fragflo159,dc=org" -w asir -f /vagrant/idp/sldapdb/proxy_users.ldif || true

echo "------ FIN IDP ------"
