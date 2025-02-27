#!/bin/bash

# Verifica que el usuario ha proporcionado una IP y un puerto o "all"
if [ $# -lt 2 ]; then
  echo "Uso: $0 <IP> <puerto|all>"
  echo "Ejemplo para escanear un puerto específico: $0 192.168.1.1 80"
  echo "Ejemplo para escanear todos los puertos: $0 192.168.1.1 all"
  exit 1
fi

# Definir variables
IP=$1
PUERTO=$2
puertos_abiertos=()
contador=1   # Empezamos desde el puerto 1
total_puertos=65535
escaneo_pausado=false
ultimo_puerto=0
progreso_actual=0
progreso_anterior=-1
tiempo_inicio=$(date +%s)  # Guardar tiempo inicial

# Función para escanear un puerto TCP con timeout rápido
scan_tcp() {
  local puerto=$1
  (timeout 1 bash -c "echo > /dev/tcp/$IP/$puerto") &>/dev/null

  if [ $? -eq 0 ]; then
    puertos_abiertos+=($puerto)
    echo -e "\n\e[32m[ABIERTO] TCP $puerto\e[0m"
  fi
}

# Función para mostrar resumen
show_summary() {
  clear  # Limpia la pantalla antes de mostrar el resumen final
  echo -e "\n======================================="
  echo -e "🔍 RESUMEN DEL ESCANEO"
  echo -e "======================================="
  if [ ${#puertos_abiertos[@]} -gt 0 ]; then
    echo -e "✅ PUERTOS ABIERTOS ENCONTRADOS:"
    for puerto in "${puertos_abiertos[@]}"; do
      echo -e "   ➜ TCP $puerto"
    done
  else
    echo -e "❌ NO SE ENCONTRARON PUERTOS ABIERTOS."
  fi
  progreso_decimal=$(awk "BEGIN {printf \"%.2f\", ($ultimo_puerto / $total_puertos) * 100}")
  echo -e "---------------------------------------"
  echo -e "📍 ULTIMO PUERTO ESCANEADO: TCP $ultimo_puerto"
  echo -e "📊 PROGRESO ALCANZADO: ${progreso_decimal}%"
  echo -e "=======================================\n"
}

# Función para pausar el escaneo y preguntar si continuar o terminar
pause_and_ask() {
  escaneo_pausado=true
  show_summary
  echo -e "⚠️  ¿DESEAS CONTINUAR CON EL ESCANEO? (S/N): "
  read -r respuesta
  if [[ "$respuesta" =~ ^[Ss]$ ]]; then
    echo -e "🔄 REANUDANDO ESCANEO...\n"
    escaneo_pausado=false
  else
    show_summary
    echo -e "✅ ESCANEO FINALIZADO.\n"
    exit 0
  fi
}

# Captura la señal SIGINT (Ctrl + C) y ejecuta pause_and_ask
trap pause_and_ask SIGINT

# Si el usuario elige un puerto específico
if [[ "$PUERTO" =~ ^[0-9]+$ ]]; then
  echo "ESCANEANDO EL PUERTO TCP $PUERTO en $IP..."
  scan_tcp $PUERTO
  if [[ ! " ${puertos_abiertos[*]} " =~ " $PUERTO " ]]; then
    echo -e "\e[31m[CERRADO] TCP $PUERTO\e[0m"
  fi
  echo "ESCANEO COMPLETADO."

# Si el usuario elige escanear todos los puertos
elif [[ "$PUERTO" == "all" ]]; then
  echo "ESCANEANDO TODOS LOS PUERTOS TCP EN $IP..."
  while [[ $contador -le $total_puertos ]]; do
    scan_tcp $contador

    # Guardar el último puerto escaneado
    ultimo_puerto=$contador

    # Actualizar progreso con decimales
    progreso_actual=$(awk "BEGIN {printf \"%.2f\", ($contador / $total_puertos) * 100}")

    # Mostrar progreso cada 10 segundos sin interferir con los puertos abiertos
    tiempo_actual=$(date +%s)
    tiempo_transcurrido=$((tiempo_actual - tiempo_inicio))

    if (( tiempo_transcurrido >= 10 )); then
      echo -ne "\r🔄 PROGRESO: ${progreso_actual}%      "
      tiempo_inicio=$tiempo_actual  # Reiniciar contador de tiempo
    fi

    ((contador++))

    # Si el escaneo está pausado, esperamos antes de continuar
    while [[ "$escaneo_pausado" == true ]]; do
      sleep 1
    done
  done

  echo -e "\n✅ ESCANEO COMPLETADO."
  show_summary
else
  echo "ERROR: EL SEGUNDO ARGUMENTO DEBE SER UN NUMERO DE PUERTO O 'all'."
  exit 1
fi
