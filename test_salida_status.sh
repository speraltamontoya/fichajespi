#!/bin/bash

# Script temporal para consultar usuarios trabajando
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/scripts-common.sh"

if ! load_config; then
    echo "ERROR: No se pudo cargar la configuración"
    exit 1
fi

echo "=== USUARIOS ACTUALMENTE TRABAJANDO ==="
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
SELECT u.id, u.numero, u.nombre_empleado, u.working, u.ultimo_fichaje 
FROM usuarios u 
WHERE u.working = 1 
AND u.de_baja = 0 
AND u.ultimo_fichaje LIKE '%ENTRADA%';"

echo
echo "=== ESTIMACIONES DISPONIBLES PARA HOY ==="
today=$(date '+%Y-%m-%d')
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
SELECT usuario_id, horas_estimadas, fecha 
FROM estimaciones 
WHERE DATE(fecha) = '$today';"

echo
echo "=== CONFIGURACIÓN ACTUAL ==="
echo "TOLERANCE_HOURS = $TOLERANCE_HOURS ($(echo "scale=0; $TOLERANCE_HOURS * 60 / 1" | bc) minutos)"
echo "DEFAULT_ESTIMATION_HOURS = $DEFAULT_ESTIMATION_HOURS"
