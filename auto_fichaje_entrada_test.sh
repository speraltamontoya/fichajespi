#!/bin/bash

# =============================================================================
# SCRIPT DE FICHAJE AUTOMÁTICO DE ENTRADA BASADO EN HORARIOS-USUARIOS
# =============================================================================
# Este script consulta la tabla horarios_usuario para determinar qué usuarios
# tienen horarios de entrada próximos y genera fichajes automáticos aleatorios.
# EJECUCIÓN: Cada 5 minutos via cron
# LÓGICA: Si hay horario de entrada en los próximos 15 minutos, genera fichaje
#         aleatorio entre ahora y 15 minutos después del horario programado.
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

# Configurar logging
setup_logging

# Configurar zona horaria UTC para todo el script
export TZ=UTC

# Ventana de tiempo para fichaje aleatorio después del horario (en minutos)
VENTANA_ALEATORIA=15

# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

# Función para escribir logs (con timestamp UTC)
log_message() {
    local message="$1"
    local timestamp=$(TZ=UTC date '+%Y-%m-%d %H:%M:%S UTC')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Función para obtener el día de la semana actual (1=Lunes, 7=Domingo)
get_current_day_of_week() {
    TZ=UTC date '+%u'
}

# Función para obtener la hora actual en formato HH:MM:SS
get_current_time() {
    TZ=UTC date '+%H:%M:%S'
}

# Función para obtener la fecha actual en formato YYYY-MM-DD
get_current_date() {
    TZ=UTC date '+%Y-%m-%d'
}

# Función para convertir tiempo HH:MM:SS a minutos desde medianoche
time_to_minutes() {
    local time="$1"
    IFS=':' read -r hours minutes seconds <<< "$time"
    echo $((hours * 60 + minutes))
}

# Función para convertir minutos desde medianoche a formato HH:MM:SS
minutes_to_time() {
    local total_minutes="$1"
    local hours=$((total_minutes / 60))
    local minutes=$((total_minutes % 60))
    printf "%02d:%02d:00" "$hours" "$minutes"
}

# Función para generar número aleatorio entre min y max
random_between() {
    local min=$1
    local max=$2
    echo $((RANDOM % (max - min + 1) + min))
}

# Función para obtener horarios próximos de la base de datos
get_upcoming_schedules() {
    local dia_semana="$1"
    
    # Consultar horarios activos para el día actual
    TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "
        SELECT 
            u.numero,
            u.nombre_empleado,
            h.hora_inicio,
            h.turno_numero,
            COALESCE(h.descripcion, '') as descripcion
        FROM horarios_usuario h 
        INNER JOIN usuarios u ON h.usuario_id = u.id
        WHERE h.dia_semana = $dia_semana 
        AND h.activo = true
        ORDER BY h.hora_inicio, h.turno_numero
    " 2>/dev/null
}

# Función de testing para mostrar horarios sin fichar
test_mode() {
    local fecha_actual=$(get_current_date)
    local dia_semana=$(get_current_day_of_week)
    local hora_actual=$(get_current_time)
    
    log_message "INFO: MODO TEST - Mostrando horarios del día $dia_semana ($fecha_actual)"
    log_message "INFO: Hora actual: $hora_actual UTC"
    
    local horarios=$(get_upcoming_schedules "$dia_semana")
    
    if [[ -z "$horarios" ]]; then
        log_message "INFO: No hay horarios configurados para el día $dia_semana"
        echo "No hay horarios configurados para el día $dia_semana ($(case $dia_semana in 1) echo "Lunes";; 2) echo "Martes";; 3) echo "Miércoles";; 4) echo "Jueves";; 5) echo "Viernes";; 6) echo "Sábado";; 7) echo "Domingo";; esac))"
        return 0
    fi
    
    echo ""
    echo "HORARIOS CONFIGURADOS PARA HOY - Día $dia_semana ($(case $dia_semana in 1) echo "Lunes";; 2) echo "Martes";; 3) echo "Miércoles";; 4) echo "Jueves";; 5) echo "Viernes";; 6) echo "Sábado";; 7) echo "Domingo";; esac)):"
    echo "================================================================"
    printf "%-15s %-25s %-10s %-6s %-20s\n" "NÚMERO" "NOMBRE" "HORARIO" "TURNO" "DESCRIPCIÓN"
    echo "--------------------------------------------------------------------------------"
    
    while IFS=$'\t' read -r numero nombre_empleado hora_inicio turno_numero descripcion; do
        [[ -z "$numero" ]] && continue
        printf "%-15s %-25s %-10s %-6s %-20s\n" "$numero" "$nombre_empleado" "$hora_inicio" "$turno_numero" "${descripcion:-"-"}"
    done <<< "$horarios"
    
    echo ""
    echo "Hora actual: $hora_actual UTC"
    
    # Mostrar próximos horarios (dentro de 15 minutos)
    local hora_actual_minutos=$(time_to_minutes "$hora_actual")
    echo ""
    echo "HORARIOS PRÓXIMOS (dentro de $VENTANA_DETECCION minutos):"
    echo "======================================================="
    
    local proximos_encontrados=false
    while IFS=$'\t' read -r numero nombre_empleado hora_inicio turno_numero descripcion; do
        [[ -z "$numero" ]] && continue
        
        local hora_horario_minutos=$(time_to_minutes "$hora_inicio")
        local diferencia=$((hora_horario_minutos - hora_actual_minutos))
        
        if [[ $diferencia -ge 0 ]] && [[ $diferencia -le $VENTANA_DETECCION ]]; then
            printf "⏰ %-15s %-25s %-10s (en %2d min)\n" "$numero" "$nombre_empleado" "$hora_inicio" "$diferencia"
            proximos_encontrados=true
        fi
    done <<< "$horarios"
    
    if [[ "$proximos_encontrados" == "false" ]]; then
        echo "No hay horarios próximos en los siguientes $VENTANA_DETECCION minutos."
    fi
    
    echo ""
}

# Función de ayuda
show_help() {
    echo "SCRIPT DE FICHAJE AUTOMÁTICO BASADO EN HORARIOS-USUARIOS"
    echo "========================================================="
    echo ""
    echo "Este script consulta la tabla horarios_usuario para generar fichajes automáticos"
    echo "cuando detecta horarios de entrada próximos (dentro de los próximos 15 minutos)."
    echo ""
    echo "Uso: $0 [MODO]"
    echo ""
    echo "MODO:"
    echo "  auto     - Ejecución automática (por defecto, para cron)"
    echo "  manual   - Ejecución manual para testing"
    echo "  test     - Muestra horarios del día actual sin generar fichajes"
    echo ""
    echo "Ejemplos:"
    echo "  $0           # Ejecución automática (cron cada 5 minutos)"
    echo "  $0 manual    # Ejecución manual para testing"
    echo "  $0 test      # Solo mostrar horarios sin fichar"
    echo ""
}

# =============================================================================
# VERIFICACIONES INICIALES
# =============================================================================

# Verificar que mysql está instalado
if ! command -v mysql &> /dev/null; then
    log_message "ERROR: mysql cliente no está instalado"
    exit 1
fi

# Verificar conexión a la base de datos
if ! TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "SELECT 1;" &> /dev/null; then
    log_message "ERROR: No se puede conectar a la base de datos"
    exit 1
fi

# =============================================================================
# PROCESAMIENTO DE ARGUMENTOS Y EJECUCIÓN
# =============================================================================

# Procesar argumentos
case "$1" in
    "-h"|"--help")
        show_help
        exit 0
        ;;
    "test")
        test_mode
        exit 0
        ;;
    *)
        echo "Por ahora solo funciona el modo test. Use: $0 test"
        exit 1
        ;;
esac
