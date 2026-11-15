#!/bin/bash
# Instalación del balanceador: Apache como proxy inverso
set -e

# Cargar variables
source "$(dirname "$0")/.env"

# Instalar Apache
apt update
apt install -y apache2

# Activar los módulos necesarios para el proxy inverso y el balanceo
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_balancer
a2enmod lbmethod_byrequests

# Evitar el aviso AH00558 sobre ServerName
echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername

# Copiar el VirtualHost y poner las IPs de los frontales
cp "$(dirname "$0")/../conf/load-balancer.conf" /etc/apache2/sites-available/load-balancer.conf
sed -i "s|__WEB1_IP__|$WEB1_IP|; s|__WEB2_IP__|$WEB2_IP|" /etc/apache2/sites-available/load-balancer.conf

# Habilitar nuestro sitio y deshabilitar el de por defecto
a2ensite load-balancer.conf
a2dissite 000-default.conf

# Comprobar la sintaxis y reiniciar
apache2ctl configtest
systemctl restart apache2

echo "Balanceador instalado correctamente"
