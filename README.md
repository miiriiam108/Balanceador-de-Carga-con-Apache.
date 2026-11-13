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

### Base de datos

#### Instalación MariaDB y comprobación



































































