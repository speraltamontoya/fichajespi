#!/bin/bash

# =============================================================================
# SCRIPT DE PRUEBA PARA FICHAJE AUTOMÁTICO
# =============================================================================

# Cargar configuración centralizada
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/scripts-common.sh"

# Cargar configuración
if ! load_config; then
    echo "ERROR: No se pudo cargar la configuración"
    exit 1
fi

# Validar configuración de base de datos
if ! validate_db_config; then
    echo "ERROR: Configuración de base de datos inválida"
    exit 1
fi

echo "=== PRUEBA DE CONEXIÓN A BASE DE DATOS ==="
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "SELECT 'Conexión exitosa' as test;"

echo ""
echo "=== PRUEBA DE USUARIOS CON ENTRADA ==="
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
SELECT u.id, u.numero, u.nombre_empleado, u.ultimo_fichaje, u.working
FROM usuarios u
WHERE u.working = 1
AND u.de_baja = 0
AND u.ultimo_fichaje LIKE '%ENTRADA%';"

echo ""
echo "=== PRUEBA DE ESTIMACIONES ==="
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
SELECT * FROM estimaciones ORDER BY fecha DESC LIMIT 5;"

echo ""
echo "=== PRUEBA DE CÁLCULO DE HORAS ==="
echo "Probando función hours_to_seconds con 1.5 horas:"
echo "scale=0; 1.5 * 3600 / 1" | bc

echo ""
echo "Probando función hours_to_seconds con 4 horas:"
echo "scale=0; 4 * 3600 / 1" | bc

echo ""
echo "=== PRUEBA COMPLETADA ==="
