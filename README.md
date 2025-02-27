# portscan.sh
## Scanner de puertos en bash
Cuando te encuentres en un equipo donde no puedas instalar nmap o algun scanner de puertos

## Uso

```./portscan.sh <IP> <puerto|all>```

## Ejemplos

- Escanear un puerto específico:

```./portscan.sh 192.168.1.1 80```

- Escanear todos los puertos:

```./portscan.sh 192.168.1.1 all```



## Notas
- Asegúrate de tener permisos de ejecución para el script. (chmod +x portscan.sh)
- El script debe ser ejecutado en un entorno compatible con bash.
- Para salirse del escaneo de puertos con la opcion 'all' debes de seleccionar las teclas "Ctrl + C", podras tener un estatus de los puertos abiertos y tener la opcion de terminar el escaneo o continuar con el.

