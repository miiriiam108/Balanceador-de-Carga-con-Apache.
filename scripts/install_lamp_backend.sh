#!/bin/bash
# Instalación del backend: servidor MySQL
set -e

# Cargar variables
source "$(dirname "$0")/.env"

# Instalar MySQL
apt update
apt install -y mysql-server

# Que MySQL escuche solo en la red interna red-bbdd
sed -i "s/^bind-address.*/bind-address = $DB_HOST/" /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql

# Crear base de datos y usuario (solo accesible desde los frontales)
mysql <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'$FRONTEND_NETWORK' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'$FRONTEND_NETWORK';
FLUSH PRIVILEGES;
EOF

echo "Backend instalado correctamente"
