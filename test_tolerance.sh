#!/bin/bash

# Script de prueba para verificar TOLERANCE_HOURS
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/scripts-common.sh"

if ! load_config; then
    echo "ERROR: No se pudo cargar la configuración"
    exit 1
fi

echo "Configuración cargada correctamente"
echo "TOLERANCE_HOURS = $TOLERANCE_HOURS"
echo "Esto equivale a $(echo "scale=0; $TOLERANCE_HOURS * 60 / 1" | bc) minutos"

# Verificar que también funciona la conversión a segundos
tolerance_seconds=$(echo "scale=0; $TOLERANCE_HOURS * 3600 / 1" | bc)
echo "En segundos: $tolerance_seconds"
