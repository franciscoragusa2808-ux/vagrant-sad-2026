#!/usr/bin/env bash

set -e
export DEBIAN_FRONTEND=noninteractive

# Asegurar que secrets.txt esté en formato Unix (por si viene en CRLF)
apt-get update -y
apt-get install -y dos2unix
dos2unix /vagrant/secrets.txt 2>/dev/null || true

# Cargar variables
source /vagrant/secrets.txt

echo "########################################"
echo " Aprovisionando IDP (OpenLDAP)"
echo "########################################"

echo "Instalando OpenLDAP y utilidades"
apt-get install -y slapd ldap-utils

echo "Configurando slapd (modo no interactivo)"
debconf-set-selections <<EOF
slapd slapd/no_configuration boolean false
slapd slapd/domain string fragflo159.org
slapd shared/organization string fragflo159
slapd slapd/password1 password $LDAP_PASS
slapd slapd/password2 password $LDAP_PASS
slapd slapd/backend select MDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
EOF

dpkg-reconfigure -f noninteractive slapd

echo "Esperando a que LDAP esté disponible"
sleep 5

echo "[*] Cargando estructura base..."
ldapadd -x -D "cn=admin,dc=fragflo159,dc=org" -w $LDAP_PASS -f "$DB_DIR/base.ldif" -c

echo "[*] Cargando grupos..."
ldapadd -x -D "cn=admin,dc=fragflo159,dc=org" -w $LDAP_PASS -f "$DB_DIR/grupos.ldif" -c

echo "[*] Cargando usuarios..."
ldapadd -x -D "cn=admin,dc=fragflo159,dc=org" -w $LDAP_PASS -f "$DB_DIR/usr.ldif" -c

echo "[*] Cargando grupo proxy_users..."
ldapadd -x -D "cn=admin,dc=fragflo159,dc=org" -w $LDAP_PASS -f "$DB_DIR/proxy_users.ldif" -c

echo "[*] Configurando acceso web a través del proxy"
cat <<EOF > /etc/apt/apt.conf.d/99proxy
Acquire::http::Proxy "http://172.1.6.2:3128/";
Acquire::https::Proxy "http://172.1.6.2:3128/";
EOF

echo "------ FIN IDP ------"
