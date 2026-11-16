#!/bin/bash
# Despliegue de la infraestructura: instala y protege cada máquina según su rol
# Uso: sudo bash deploy.sh <backend|frontend|balanceador>
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/.env"

ROL="$1"

# Comprobar que se ejecuta como administrador
if [ "$EUID" -ne 0 ]; then
  echo "Ejecuta el script con sudo: sudo bash deploy.sh <rol>"
  exit 1
fi

# Cortafuegos: política base (denegar la entrada, permitir la salida)
base_cortafuegos() {
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing
}

case "$ROL" in
  backend)
    echo ">>> Instalando el backend (MySQL)"
    bash "$DIR/install_lamp_backend.sh"

    echo ">>> Configurando el cortafuegos del backend"
    base_cortafuegos
    for IP in "$WEB1_DB_IP" "$WEB2_DB_IP"; do
      ufw allow in on "$IFACE" from "$IP" to any port 3306 proto tcp
      ufw allow in on "$IFACE" from "$IP" to any port 22 proto tcp
    done
    ufw --force enable
    ;;

  frontend)
    echo ">>> Instalando el frontend (Apache + PHP)"
    bash "$DIR/install_lamp_frontend.sh"

    echo ">>> Configurando el cortafuegos del frontend"
    base_cortafuegos
    ufw allow in on "$IFACE" from "$BALANCER_IP" to any port 80 proto tcp
    ufw allow in on "$IFACE" from "$BALANCER_IP" to any port 22 proto tcp
    ufw --force enable
    ;;

  balanceador)
    echo ">>> Instalando el balanceador (Apache como proxy inverso)"
    bash "$DIR/install_load_balancer.sh"

    echo ">>> Configurando el cortafuegos del balanceador"
    base_cortafuegos
    ufw allow in on "$IFACE" to any port 80 proto tcp
    ufw allow in on "$IFACE" to any port 443 proto tcp
    ufw allow in on "$IFACE" from "$LAN_NETWORK" to any port 22 proto tcp
    ufw --force enable
    ;;

  *)
    echo "Uso: sudo bash deploy.sh <backend|frontend|balanceador>"
    exit 1
    ;;
esac

echo ">>> Estado del cortafuegos"
ufw status verbose
echo ">>> Despliegue del rol '$ROL' completado"
