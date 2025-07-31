#!/bin/bash

# Script para verificar el resultado del fichaje
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/scripts-common.sh"

if ! load_config; then
    echo "ERROR: No se pudo cargar la configuración"
    exit 1
fi

echo "=== ESTADO ACTUALIZADO DEL USUARIO ==="
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
SELECT u.id, u.numero, u.nombre_empleado, u.working, u.ultimo_fichaje 
FROM usuarios u 
WHERE u.numero = '4086855489';"

echo
echo "=== ÚLTIMOS FICHAJES DEL USUARIO ==="
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
SELECT id, dia, hora, origen, tipo 
FROM fichajes 
WHERE usuario_id = 4 
AND dia = '$(date '+%Y-%m-%d')'
ORDER BY dia DESC, hora DESC 
LIMIT 5;"

echo
echo "=== VERIFICACIÓN DE CÁLCULOS ==="
echo "Entrada: 2025-07-31 15:51:00 UTC"
echo "Estimación: 2 horas"
echo "Tolerancia: $TOLERANCE_HOURS horas ($(echo "scale=0; $TOLERANCE_HOURS * 60 / 1" | bc) minutos)"
echo "Trigger esperado: 18:21:00 UTC (15:51 + 2:00 + 0:30)"
echo "Hora actual: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
