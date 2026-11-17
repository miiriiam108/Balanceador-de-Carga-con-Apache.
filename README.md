# Balanceador-de-Carga-con-Apache.

## ÍNDICE
1. Introducción
2. Arquitectura de la infraestructura
3. Creación del repositorio GitHub
4. Configuración de AWS
5. Creación de las instancias EC2
6. Configuración del balanceador Apache
7. Configuración de los servidores web
8. Configuración del servidor de base de datos
9. Configuración de HTTPS con CertBot
10. Configuración de ACL y Security Groups
11. Pruebas de funcionamiento
12. Conclusiones

## 1. INTRODUCCIÓN
El objetivo de esta práctica es desplegar una arquitectura web de tres capas en AWS utilizando un balanceador de carga basado en Apache, dos servidores web y un servidor de base de datos.

La infraestructura está formada por:

- Un balanceador de carga Apache.
- Dos servidores web.
- Un servidor de base de datos.
- Redes configuradas con las medidas de seguridad necesarias.

## Arquitectura de la infraestructura

Tengo 4 máquinas virtuales

- MiriamPorroBalanceador
- MiriamPorroWeb1
- MiriamPorroWeb2
- MiriamPorroBBDD


![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20102244.png)

En las que a cada una le he puesto sus tarjetas de red correspondientes

- Balanceador
  
![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20102918.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20102925.png)


- Web 1
  
![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20102945.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20103000.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20103013.png)

- Web 2

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20103038.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20103052.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20103104.png)

- BBDD

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20103121.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20103129.png)

## Configuración de red

1. **Balanceador:**

Al arrancar la máquina "MiriamPorroBalanceador", se comprueban sus interfaces de red con el comando `ip -br a` 

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20104238.png)

- **`lo`**: interfaz de bucle local (*loopback*) con la dirección `127.0.0.1`. Es interna del sistema y no se modifica.


- **`enp0s3`**: corresponde al **adaptador 1** de VirtualBox, configurado en modo puente. Tiene una dirección IP (`192.168.100.211`), por lo que ya tiene conectividad con la red local y con Internet.


- **`enp0s8`**: corresponde al **adaptador 2**, conectado a la red interna red-web. Solo tiene una dirección IPv6 de enlace local (`fe80::...`) y no tiene dirección IPv4, ya que en una red interna de VirtualBox no existe ningún servidor DHCP. Por ello se le asignará una dirección IP estática.

Luego le asigno el nombre de equipo y se configura la interfaz `enp0s8` con una IP fija mediante Netplan: `sudo hostnamectl set-hostname balanceador` y `sudo nano /etc/netplan/99-practica.yaml`

Dentro del fichero he escrito:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: false
      addresses:
        - 192.168.10.10/24
```


![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20104555.png)

Se aplica la configuración y se comprueba con:

`sudo netplan apply` -> para ver si tenemos errores de sintaxis en el fichero
`ip -br a` -> 
`hostname` -> para ver el nombre de usuario

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20110641.png)

- El nombre de equipo es **`balanceador`**.
- La interfaz `enp0s3` (modo puente) mantiene su dirección por DHCP, `192.168.100.213`, y por tanto sale a Internet.
- La interfaz `enp0s8` tiene la dirección estática **`192.168.10.10/24`**.


2. **Web1:**

Ahora he arrancado la máquina "MiriamPorroWeb1" he vuelto a seguir los mismos pasos que en la máquina anterior. en este caso de nombre le he puesto "Web1" 

`sudo hostnamectl set-hostname Web1`

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20114841.png)


en el fichero he puesto: 
```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.10.11/24
    enp0s8:
      dhcp4: false
      addresses:
        - 192.168.20.11/24
    enp0s9:
      dhcp4: true
```
![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20115210.png)

en este caso de nombre le he puesto "Web1" 

`sudo hostnamectl set-hostname Web1`

También he comprobado que desde Web1 hace ping a balanceador

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20115732.png)

- Las interfaces `enp0s3` y `enp0s8` tienen las direcciones estáticas **`192.168.10.11/24`** y **`192.168.20.11/24`**.
- La interfaz `enp0s9` mantiene su dirección por DHCP (`10.0.4.15`).

**ERROR** Al principio no me ha echo ping porque tenía la máquina MiriamPorroBalanceador apagada, una vez encendida si me ha echo ping 

3. **Web2:**

Abro la segunda máquina "MiriamPorroWeb2" y realizo los mismos pasos esta vez con el nombre "Web2", y editando el fichero:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.10.12/24
    enp0s8:
      dhcp4: false
      addresses:
        - 192.168.20.12/24
    enp0s9:
      dhcp4: true
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20121127.png)
![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20121742.png)
![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20121947.png)

Como se puede observar también hace ping a internet y a la máquina del balanceador


4. **BBDD**

Abro la máquina "MiriamPorroBBDD" y realizo los mismos pasos, este 2 tarjetas como balanceador, no tres.

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20123043.png)

Contenido del fichero: 

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.20.10/24
    enp0s8:
      dhcp4: true
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20123333.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20123621.png)

En este caso hago ping con internet, con Web1 y con Web 2

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20123705.png)

Desde el balanceador le hago ping a la base de datos y como observamos no llega, porque el balanceador no está en red-bbdd

## Instalación de los servidores
La instalación de cada capa se automatiza mediante scripts de Bash, almacenados en el directorio `scripts` del repositorio. Las variables de configuración se centralizan en el fichero `.env`, de modo que los scripts no contienen valores fijos.

Para ejecutar un script en una máquina, se clona el repositorio y se lanza con privilegios de administrador:

```bash
git clone https://github.com/miiriiam108/Balanceador-de-Carga-con-Apache..git repo
cd repo/scripts
```
**ERROR** No tengo captura porque al clonar los comandos se han ido hacia arriba y no me ha dado tiempo de hacer captura

### Base de datos

#### Script `install_lamp_backend.sh`

El servidor de base de datos se instala en la máquina `MiriamPorroBBDD`, que pertenece a la capa 3. El script realiza las siguientes tareas:

1. Instala el servidor **MySQL**.
2. Modifica el parámetro `bind-address` para que MySQL escuche únicamente en la dirección de la red interna `red-bbdd` (`192.168.20.10`).
3. Crea la base de datos `practica`.
4. Crea el usuario `appuser`, que solo puede conectarse desde la red `192.168.20.0/24`, es decir, desde los servidores web, y le concede permisos únicamente sobre esa base de datos.


#### Instalación Mysql y comprobación

Tras ejecutar el script, se comprueba que el servicio está en funcionamiento:
`systemctl status mysql`

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20121053.png)

#### Comprobación de la dirección de escucha

Ejecuto `sudo ss -tlnp | grep 3306` para ver si el servicio escucha

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20122728.png)

#### Comprobación de la base de datos y el usuario

`sudo mysql -e "SHOW DATABASES; SELECT user,host FROM mysql.user WHERE user='appuser';"`

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20121537.png)

En la captura se observa la base de datos `practica` y el usuario `appuser`, restringido al host `192.168.20.%`, por lo que solo los servidores web pueden conectarse a ella.

### Servidores web (frontales)

#### Script `install_lamp_frontend.sh`

Los servidores web se instalan en las máquinas `MiriamPorroWeb1` y `MiriamPorroWeb2`, que pertenecen a la capa 2. Se utiliza el mismo script en ambas. El script realiza las siguientes tareas:

1. Instala **Apache**, **PHP** y la extensión `php-mysql`. El servidor MySQL no se instala aquí, porque se encuentra en el backend.
2. Sustituye la página por defecto de Apache por una página PHP de prueba.
3. Configura en esa página los datos de conexión a la base de datos, leídos del fichero `.env`.
4. Habilita y reinicia el servicio `apache2`.

La página muestra el **nombre del servidor** que responde y un mensaje almacenado en la tabla `mensajes` de la base de datos. Así se puede comprobar el balanceo de carga y, a la vez, la conexión entre las capas 2 y 3.

```bash
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
$c = new mysqli("__DB_HOST__", "__DB_USER__", "__DB_PASSWORD__", "__DB_NAME__");
if ($c->connect_error) {
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
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20123207.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20123557.png)


#### Instalación en Web1

En la máquina `MiriamPorroWeb1` se clona el repositorio y se ejecuta el script:

```bash
git clone https://github.com/miiriiam108/Balanceador-de-Carga-con-Apache..git repo
cd repo/scripts
sudo bash install_lamp_frontend.sh
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20124155.png)


#### Instalación en Web2

El procedimiento es idéntico en la máquina `MiriamPorroWeb2`:

```bash
git clone https://github.com/miiriiam108/Balanceador-de-Carga-con-Apache..git repo
cd repo/scripts
sudo bash install_lamp_frontend.sh
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20124424.png)


#### Comprobación de Web1

Se comprueba que Apache está en ejecución y que la página responde correctamente:

```bash
systemctl status apache2
curl http://localhost
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20124557.png)


#### Comprobación de Web2

```bash
systemctl status apache2
curl http://localhost
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20124745.png)


En las 2 capturas se comprueba que:

- Apache está en estado **`active (running)`**.
- La página indica el nombre del servidor que responde: **`Web1`** y **`Web2`**, respectivamente.
- Aparece el mensaje **«Conexión con la base de datos correcta»**, por lo que los dos servidores web alcanzan la base de datos a través de la red `red-bbdd`.
- Se muestra el mensaje almacenado en la tabla `mensajes`, leído desde MySQL.


### Balanceador de carga

#### Script `install_load_balancer.sh`

El balanceador se instala en la máquina `MiriamPorroBalanceador`, que pertenece a la capa 1. En esta práctica se utiliza **Apache HTTP Server configurado como proxy inverso**. Un proxy inverso es un servidor intermedio: el cliente envía las peticiones al balanceador y este las reparte entre los servidores web, devolviendo después sus respuestas al cliente.

El script realiza las siguientes tareas:

1. Instala **Apache**.
2. Activa los módulos necesarios:
   - `proxy`: permite configurar Apache como proxy inverso.
   - `proxy_http`: añade el soporte para el protocolo HTTP.
   - `proxy_balancer`: permite definir un grupo de servidores entre los que repartir la carga.
   - `lbmethod_byrequests`: implementa la política de balanceo **Round Robin**.
3. Define la directiva `ServerName` para evitar el aviso `AH00558` de Apache.
4. Copia el fichero `conf/load-balancer.conf` a `/etc/apache2/sites-available/` y sustituye las direcciones de los frontales por las definidas en `.env`.
5. Habilita el nuevo sitio, deshabilita el sitio por defecto, comprueba la sintaxis y reinicia Apache.

#### Fichero `load-balancer.conf`

```apache
<VirtualHost *:80>
    <Proxy balancer://mycluster>
        # Servidor 1
        BalancerMember http://192.168.10.11
        # Servidor 2
        BalancerMember http://192.168.10.12
        # Política de balanceo: Round Robin
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPreserveHost On
    ProxyPass / balancer://mycluster/
    ProxyPassReverse / balancer://mycluster/
</VirtualHost>
```

- `BalancerMember` define cada uno de los servidores web del grupo.
- `lbmethod=byrequests` reparte las peticiones de forma secuencial: la primera al servidor 1, la siguiente al servidor 2, y así sucesivamente.
- `ProxyPass` envía al grupo todas las peticiones que llegan a la raíz del sitio.
- `ProxyPassReverse` reescribe las cabeceras de las respuestas para que el cliente siempre vea la dirección del balanceador.
- `ProxyPreserveHost On` mantiene la cabecera `Host` original de la petición.


#### Instalación y comprobación del balanceo

En la máquina del balanceador se clona el repositorio y se ejecuta el script. Después se comprueba que Apache está en ejecución y se lanzan cuatro peticiones seguidas al balanceador:

```bash
git clone https://github.com/miiriiam108/Balanceador-de-Carga-con-Apache..git repo
cd repo/scripts
sudo bash install_load_balancer.sh
systemctl status apache2
for i in 1 2 3 4; do curl -s http://localhost | grep "servidor web"; done
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20130653.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20132814.png)

- El script finaliza con el mensaje **Balanceador instalado correctamente**.
- Apache está en estado **`active (running)`**.
- Las cuatro respuestas alternan entre **Web1** y **Web2**, lo que confirma que el balanceador reparte las peticiones de forma secuencial (Round Robin).

#### Comprobación desde el navegador

Se accede a la dirección del balanceador desde un navegador y se recarga la página. Cada petición la atiende un servidor distinto:

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20133525.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-15%20133604.png)



### Servidores web (Web1 y Web2)

Los servidores web solo deben recibir tráfico del balanceador. Se aplican las mismas reglas en ambos, a través de la interfaz `enp0s3`, que corresponde a la red interna `red-web`:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on enp0s3 from 192.168.10.10 to any port 80 proto tcp
sudo ufw allow in on enp0s3 from 192.168.10.10 to any port 22 proto tcp
sudo ufw enable
sudo ufw status verbose
```


![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20094707.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20094728.png)

Desde el balanceador se comprueba que el puerto 80 de Web1 responde y que un puerto no autorizado (8080) se bloquea:

```bash
nc -zv -w 3 192.168.10.11 80
nc -zv -w 3 192.168.10.11 8080
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20094851.png)

También se comprueba que un servidor web no puede acceder al otro. Desde Web2 se intenta conectar con Web1:

```bash
curl -m 3 http://192.168.10.11
```
![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20094936.png)


La conexión falla por tiempo de espera, porque solo el balanceador tiene permitido el acceso. Así se limita el movimiento lateral entre servidores en caso de que uno de ellos se viera comprometido.

### Balanceador

El balanceador es la única máquina expuesta a la red pública. Se permite el tráfico web desde cualquier origen y el acceso SSH solo desde la red local:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on enp0s3 to any port 80 proto tcp
sudo ufw allow in on enp0s3 to any port 443 proto tcp
sudo ufw allow in on enp0s3 from 192.168.100.0/23 to any port 22 proto tcp
sudo ufw enable
sudo ufw status verbose
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20095026.png)

#### IP fija del balanceador

En AWS, la máquina de la capa 1 se hace pública asignándole una **IP elástica**, una dirección que no cambia aunque la instancia se detenga o se reinicie. En este escenario con VirtualBox, el balanceador obtiene su dirección de la red local mediante el adaptador puente. Esa dirección la reparte el router por DHCP y puede cambiar cada vez que se reinicia la máquina o se cambia de red, por lo que se sustituye por una **dirección IP estática**.

Antes de elegir la dirección, se comprueba la configuración actual de la red y que la dirección elegida no está en uso por ningún otro dispositivo:

```bash
ip -br a
ip route | grep default
ping -c 3 192.168.100.250
```

El `ping` responde con `Destination Host Unreachable`, por lo que la dirección `192.168.100.250` está libre. La puerta de enlace de la red es `192.168.100.1`.

Se edita el fichero de Netplan para que la interfaz `enp0s3` (adaptador puente) use una dirección fija, con su puerta de enlace y sus servidores DNS:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.100.250/23
      routes:
        - to: default
          via: 192.168.100.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
    enp0s8:
      dhcp4: false
      addresses:
        - 192.168.10.10/24
```

Para evitar quedarse sin conexión por un error de sintaxis, la configuración se aplica con `netplan try`, que revierte los cambios automáticamente si no se confirman en 120 segundos:

```bash
sudo netplan try
```

Después se comprueba el resultado:

```bash
ip -br a
ip route | grep default
ping -c 3 8.8.8.8
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20095505.png)

ANTES

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20095618.png)

DESPUÉS

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20095842.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20095959.png)


En la captura se comprueba que:

- La configuración se ha aceptado (`Configuration accepted`).
- La interfaz `enp0s3` tiene la dirección estática **`192.168.100.250/23`**.
- La ruta por defecto pasa a ser estática (`proto static`) y no dinámica (`proto dhcp`), con la puerta de enlace `192.168.100.1`.
- El `ping` a `8.8.8.8` responde sin pérdida de paquetes, por lo que la máquina conserva la salida a Internet.

Por último, se comprueba que la dirección se mantiene tras reiniciar la máquina:

```bash
sudo reboot
ip -br a
```
![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20100544.png)


## Automatización del despliegue

El script `deploy.sh` reúne en un único punto de entrada la instalación de cada servidor y la configuración de su cortafuegos. Las máquinas de las capas 2 y 3 están en redes privadas y no son accesibles entre sí desde el exterior, por lo que el script se ejecuta **en cada máquina indicando su rol**:

```bash
sudo bash deploy.sh backend        
sudo bash deploy.sh frontend       
sudo bash deploy.sh balanceador    
```

Para cada rol, el script realiza las siguientes tareas:

1. Carga las variables del fichero `.env`.
2. Ejecuta el script de instalación correspondiente (`install_lamp_backend.sh`, `install_lamp_frontend.sh` o `install_load_balancer.sh`).
3. Aplica las reglas del cortafuegos de esa capa: política de entrada en *denegar* y permiso únicamente para el tráfico necesario.
4. Muestra el estado final del cortafuegos.

Las direcciones y la interfaz de red que usan las reglas del cortafuegos se definen en el fichero `.env`, por lo que el script no contiene valores fijos:

```bash
IFACE=enp0s3
BALANCER_IP=192.168.10.10
WEB1_DB_IP=192.168.20.11
WEB2_DB_IP=192.168.20.12
LAN_NETWORK=192.168.100.0/23
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20103514.png)

### Despliegue de la base de datos

En la máquina `MiriamPorroBBDD` se actualiza el repositorio y se ejecuta el script con el rol `backend`:

```bash
cd ~/repo
git pull
cd scripts
sudo bash deploy.sh backend
```
![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20104038.png)

Al finalizar, el script muestra el mensaje de despliegue completado y las reglas del cortafuegos: solo se permiten MySQL (3306) y SSH (22) desde las direcciones de Web1 y Web2.

### Despliegue de los servidores web

El mismo comando, con el rol `frontend`, se ejecuta en Web1 y en Web2:

```bash
sudo bash deploy.sh frontend
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20104208.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20104305.png)


n ambas máquinas, el cortafuegos queda configurado para permitir HTTP (80) y SSH (22) únicamente desde el balanceador (`192.168.10.10`).

Tras el despliegue, se comprueba que cada servidor responde y que se conecta a la base de datos:

```bash
curl -m 10 http://localhost
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20104506.png)


![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20104420.png)


En ambas capturas la página muestra el nombre del servidor que responde (**Web1** y **Web2**), el mensaje **«Conexión con la base de datos correcta»** y el mensaje almacenado en MySQL.

### Despliegue del balanceador

En la máquina `MiriamPorroBalanceador` se ejecuta el rol `balanceador`:

```bash
sudo bash deploy.sh balanceador
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-16%20104620.png)

El cortafuegos del balanceador permite HTTP (80) y HTTPS (443) desde cualquier origen y SSH (22) solo desde la red local (`192.168.100.0/23`). Las reglas marcadas como `(v6)` son las equivalentes para IPv6, que `ufw` crea automáticamente.

### Aislamiento de las capas privadas

Durante la instalación, Web1, Web2 y BBDD necesitaban salida a Internet para descargar paquetes, por lo que tenían un adaptador de red en modo **NAT**. Una vez instalados y configurados todos los servicios, este adaptador ya no es necesario, y mantenerlo supondría una vía de entrada y de salida innecesaria hacia las capas privadas.

Para evitar que el sistema espere a una interfaz inexistente en cada arranque, la interfaz NAT se marca como opcional en Netplan:

```yaml
    enp0s9:
      dhcp4: true
      optional: true
```

```yaml
    enp0s8:
      dhcp4: true
      optional: true
```

![Captura 1](img/Captura%20de%20pantalla%202026-11-17%20125624.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-17%20125718.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-17%20125819.png)

Después se apagan las máquinas y se desactiva el adaptador NAT desde VirtualBox:

![Captura 1](img/Captura%20de%20pantalla%202026-11-17%20130058.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-17%20130115.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-17%20130148.png)

Al arrancar de nuevo, se comprueba que las máquinas privadas ya no tienen conexión a Internet:

![Captura 1](img/Captura%20de%20pantalla%202026-11-17%20130622.png)

![Captura 1](img/Captura%20de%20pantalla%202026-11-17%20130627.png)


El `ping` falla en las máquinas, lo que confirma que las capas 2 y 3 quedan aisladas de Internet. A pesar de ello, la aplicación sigue funcionando, ya que toda la comunicación necesaria se realiza a través de las redes internas `red-web` y `red-bbdd`.














































































