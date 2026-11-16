#!/bin/bash
# Instalación del frontend: Apache + PHP + conexión a MySQL
set -e

# Cargar variables
source "$(dirname "$0")/.env"

# Instalar la pila LAMP (sin MySQL, que está en el backend)
apt update
apt install -y apache2 php libapache2-mod-php php-mysql

# Sustituir la página por defecto por nuestra aplicación
rm -f /var/www/html/index.html

cat > /var/www/html/index.php <<'EOF'
<?php
mysqli_report(MYSQLI_REPORT_OFF);
$servidor = gethostname();
?>
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Práctica balanceador</title></head>
<body>
<h1>Práctica: balanceador de carga con Apache</h1>
<h2>Responde el servidor web: <?php echo $servidor; ?></h2>
<?php
$c = mysqli_init();
$c->options(MYSQLI_OPT_CONNECT_TIMEOUT, 3);
@$c->real_connect("__DB_HOST__", "__DB_USER__", "__DB_PASSWORD__", "__DB_NAME__");if ($c->connect_errno) {
    echo "<p style='color:red'>Error de conexión con la base de datos.</p>";
} else {
    echo "<p style='color:green'>Conexión con la base de datos correcta.</p>";
    $r = $c->query("SELECT texto FROM mensajes LIMIT 1");
    if ($r && $fila = $r->fetch_assoc()) {
        echo "<p>Mensaje de la base de datos: " . htmlspecialchars($fila['texto']) . "</p>";
    }
}
?>
</body>
</html>
EOF

# Rellenar la conexión con las variables del .env
sed -i "s|__DB_HOST__|$DB_HOST|; s|__DB_USER__|$DB_USER|; s|__DB_PASSWORD__|$DB_PASSWORD|; s|__DB_NAME__|$DB_NAME|" /var/www/html/index.php

systemctl enable apache2
systemctl restart apache2

echo "Frontend instalado correctamente"
