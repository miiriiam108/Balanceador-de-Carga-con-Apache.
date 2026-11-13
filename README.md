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

- Balanceador:

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

`sudo netplan apply`
`ip -br a`
`hostname`

![Captura 1](img/Captura%20de%20pantalla%202026-11-13%20110641.png)

- El nombre de equipo es **`balanceador`**.
- La interfaz `enp0s3` (modo puente) mantiene su dirección por DHCP, `192.168.100.213`, y por tanto sale a Internet.
- La interfaz `enp0s8` tiene la dirección estática **`192.168.10.10/24`**.
