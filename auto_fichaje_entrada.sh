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

# Cargar configuración común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts-common.sh"

# Inicializar configuración
init_script_config "auto_fichaje_entrada.sh"

# Verificar herramientas requeridas
check_required_tools

# Configurar zona horaria por defecto si no está definida
DEFAULT_TIMEZONE="${DEFAULT_TIMEZONE:-Europe/Madrid}"

# Configurar ventanas de tiempo
VENTANA_DETECCION="${VENTANA_DETECCION:-15}"
VENTANA_ALEATORIA="${VENTANA_ALEATORIA:-15}"

# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

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
    
    # Generar segundos aleatorios entre 0 y 59 para mayor realismo
    local seconds=$((RANDOM % 60))
    
    printf "%02d:%02d:%02d" "$hours" "$minutes" "$seconds"
}

# Función para generar número aleatorio entre min y max
random_between() {
    local min=$1
    local max=$2
    echo $((RANDOM % (max - min + 1) + min))
}

# Función para convertir hora local a UTC
convert_local_to_utc() {
    local hora_local="$1"       # HH:MM:SS
    local timezone="$2"         # Europe/Madrid, UTC, etc.
    local fecha_actual="$3"     # YYYY-MM-DD
    
    # Si timezone está vacío o es NULL, usar DEFAULT_TIMEZONE
    if [[ -z "$timezone" ]] || [[ "$timezone" == "NULL" ]]; then
        timezone="$DEFAULT_TIMEZONE"
    fi
    
    # Si es UTC, no hacer conversión
    if [[ "$timezone" == "UTC" ]]; then
        echo "$hora_local"
        return
    fi
    
    # Enfoque simplificado para Europe/Madrid
    local hora_utc
    if [[ "$timezone" == "Europe/Madrid" ]]; then
        # Madrid en verano (julio) es UTC+2
        local hora_minutos=$(time_to_minutes "$hora_local")
        local hora_utc_minutos=$((hora_minutos - 120))  # Restar 2 horas (120 minutos)
        
        # Manejar overflow/underflow
        if [[ $hora_utc_minutos -lt 0 ]]; then
            hora_utc_minutos=$((hora_utc_minutos + 1440))  # +24 horas
        fi
        
        hora_utc=$(minutes_to_time $hora_utc_minutos)
    else
        # Para otras zonas horarias, usar hora local como fallback
        hora_utc="$hora_local"
    fi
    
    echo "$hora_utc"
}

# Función para obtener zona horaria de un horario específico
get_schedule_timezone() {
    local numero_usuario="$1"
    local dia_semana="$2"
    local hora_inicio="$3"
    
    # Obtener timezone desde la base de datos
    local timezone=$(TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "
        SELECT COALESCE(h.timezone, '$DEFAULT_TIMEZONE') as timezone
        FROM horarios_usuario h 
        INNER JOIN usuarios u ON h.usuario_id = u.id
        WHERE u.numero = '$numero_usuario'
        AND h.dia_semana = $dia_semana 
        AND h.hora_inicio = '$hora_inicio'
        AND h.activo = true
        LIMIT 1
    " 2>/dev/null)
    
    # Si no se encuentra, usar DEFAULT_TIMEZONE
    if [[ -z "$timezone" ]]; then
        timezone="$DEFAULT_TIMEZONE"
    fi
    
    echo "$timezone"
}

# Función para obtener el siguiente ID de la secuencia
get_next_id() {
    local next_id=$(TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "SELECT next_val FROM hibernate_sequence;")
    echo $next_id
}

# Función para actualizar el contador de hibernate_sequence
update_hibernate_sequence() {
    local current_id=$1
    local new_id=$((current_id + 1))
    TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "UPDATE hibernate_sequence SET next_val = $new_id;"
}

# Función para obtener horarios próximos de la base de datos
get_upcoming_schedules() {
    local dia_semana="$1"
    local hora_actual_minutos="$2"
    local ventana_minutos="$3"
    
    # Consultar horarios activos para el día actual incluyendo timezone
    TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "
        SELECT 
            u.numero,
            u.nombre_empleado,
            h.hora_inicio,
            h.turno_numero,
            COALESCE(h.descripcion, '') as descripcion,
            COALESCE(h.timezone, '$DEFAULT_TIMEZONE') as timezone
        FROM horarios_usuario h 
        INNER JOIN usuarios u ON h.usuario_id = u.id
        WHERE h.dia_semana = $dia_semana 
        AND h.activo = true
        ORDER BY h.hora_inicio, h.turno_numero
    " 2>/dev/null
}

# Función para verificar si ya existe una entrada para la fecha específica
check_existing_entrada() {
    local user_numero="$1"
    local fecha="$2"  # formato YYYY-MM-DD
    
    local count=$(TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "
        SELECT COUNT(*) FROM fichajes 
        WHERE usuario_id = (SELECT id FROM usuarios WHERE numero = '$user_numero')
        AND dia = '$fecha'
        AND tipo = 'ENTRADA'
    " 2>/dev/null)
    
    echo "${count:-0}"
}

# Función para verificar si un horario está próximo (dentro de la ventana de detección)
is_schedule_upcoming() {
    local hora_horario_local="$1"   # HH:MM:SS del horario en zona local
    local timezone="$2"             # Zona horaria del horario
    local hora_actual_minutos="$3"  # minutos actuales desde medianoche UTC
    local ventana_minutos="$4"      # ventana de detección en minutos
    local fecha_actual="$5"         # YYYY-MM-DD
    
    # Convertir hora local a UTC
    local hora_horario_utc=$(convert_local_to_utc "$hora_horario_local" "$timezone" "$fecha_actual")
    local hora_horario_minutos=$(time_to_minutes "$hora_horario_utc")
    local diferencia=$((hora_horario_minutos - hora_actual_minutos))
    
    # Verificar si el horario está dentro de los próximos X minutos
    if [[ $diferencia -ge 0 ]] && [[ $diferencia -le $ventana_minutos ]]; then
        return 0  # está próximo
    else
        return 1  # no está próximo
    fi
}

# Función para generar hora de fichaje aleatoria
generate_random_entry_time() {
    local hora_horario_local="$1"    # HH:MM:SS del horario programado en zona local
    local timezone="$2"              # Zona horaria del horario
    local hora_actual_minutos="$3"   # minutos actuales desde medianoche UTC
    local ventana_aleatoria="$4"     # ventana aleatoria en minutos
    local fecha_actual="$5"          # YYYY-MM-DD
    
    # Convertir hora local a UTC
    local hora_horario_utc=$(convert_local_to_utc "$hora_horario_local" "$timezone" "$fecha_actual")
    local hora_horario_minutos=$(time_to_minutes "$hora_horario_utc")
    
    # Generar tiempo aleatorio entre ahora y horario + ventana
    local min_tiempo=$hora_actual_minutos
    local max_tiempo=$((hora_horario_minutos + ventana_aleatoria))
    
    # Si el horario ya pasó, usar desde ahora hasta ventana aleatoria desde ahora
    if [[ $hora_horario_minutos -lt $hora_actual_minutos ]]; then
        max_tiempo=$((hora_actual_minutos + ventana_aleatoria))
    fi
    
    local tiempo_aleatorio=$(random_between $min_tiempo $max_tiempo)
    minutes_to_time $tiempo_aleatorio
}

# Función para calcular horas estimadas de trabajo para un usuario en un día
calculate_estimated_hours() {
    local user_numero="$1"
    local dia_semana="$2"
    
    # Obtener todos los horarios del usuario para este día
    local horarios_usuario=$(TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "
        SELECT 
            h.hora_inicio,
            h.hora_fin
        FROM horarios_usuario h 
        INNER JOIN usuarios u ON h.usuario_id = u.id
        WHERE u.numero = '$user_numero'
        AND h.dia_semana = $dia_semana 
        AND h.activo = true
        ORDER BY h.turno_numero
    " 2>/dev/null)
    
    if [[ -z "$horarios_usuario" ]]; then
        echo "0.00"
        return
    fi
    
    local total_minutos=0
    
    # Calcular la suma de todos los turnos
    while IFS=$'\t' read -r hora_inicio hora_fin; do
        [[ -z "$hora_inicio" ]] && continue
        
        local inicio_minutos=$(time_to_minutes "$hora_inicio")
        local fin_minutos=$(time_to_minutes "$hora_fin")
        local duracion_minutos=$((fin_minutos - inicio_minutos))
        
        # Si la hora fin es menor que la de inicio, probablemente cruce medianoche
        if [[ $duracion_minutos -lt 0 ]]; then
            duracion_minutos=$((duracion_minutos + 1440))  # Añadir 24 horas
        fi
        
        total_minutos=$((total_minutos + duracion_minutos))
        
    done <<< "$horarios_usuario"
    
    # Convertir minutos a horas con 2 decimales
    local horas_estimadas=$(echo "scale=2; $total_minutos / 60" | bc -l)
    echo "$horas_estimadas"
}

# Función para insertar estimación de horas
insert_estimation() {
    local user_numero="$1"
    local fecha="$2"  # formato YYYY-MM-DD
    local horas_estimadas="$3"
    local hora_fichaje="$4"  # formato HH:MM:SS - hora del fichaje de entrada
    
    # Crear datetime completo para la estimación (mismo que el fichaje)
    local datetime_estimacion="$fecha $hora_fichaje"
    
    # Verificar si ya existe una estimación para este usuario y fecha
    local existing_estimation=$(TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "
        SELECT COUNT(*) FROM estimaciones 
        WHERE usuario_id = '$user_numero' 
        AND DATE(fecha) = '$fecha'
    " 2>/dev/null)
    
    if [[ $existing_estimation -gt 0 ]]; then
        log_message "INFO" "Ya existe estimación para usuario $user_numero en $fecha. Actualizando." "$LOG_FILE"
        
        # Actualizar estimación existente con la hora del fichaje
        TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
            UPDATE estimaciones 
            SET horas_estimadas = $horas_estimadas, fecha = '$datetime_estimacion'
            WHERE usuario_id = '$user_numero' 
            AND DATE(fecha) = '$fecha';
        "
    else
        # Insertar nueva estimación usando la hora específica del fichaje
        TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
            INSERT INTO estimaciones (usuario_id, horas_estimadas, fecha)
            VALUES ('$user_numero', $horas_estimadas, '$datetime_estimacion');
        "
    fi
    
    if [[ $? -eq 0 ]]; then
        log_message "INFO" "Estimación insertada/actualizada para usuario $user_numero: $horas_estimadas horas a las $hora_fichaje UTC" "$LOG_FILE"
        return 0
    else
        log_message "ERROR" "No se pudo insertar estimación para usuario $user_numero" "$LOG_FILE"
        return 1
    fi
}

# Función para insertar fichaje de entrada
insert_fichaje_entrada() {
    local user_numero="$1"
    local fecha="$2"
    local hora="$3"
    local descripcion="$4"
    
    # Obtener user_id desde numero
    local user_id=$(TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "
        SELECT id FROM usuarios WHERE numero = '$user_numero'
    " 2>/dev/null)
    
    if [[ -z "$user_id" ]]; then
        log_message "ERROR" "No se encontró usuario con número $user_numero" "$LOG_FILE"
        return 1
    fi
    
    # Obtener siguiente ID
    local fichaje_id=$(get_next_id)
    
    # Insertar fichaje de entrada
    TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
        INSERT INTO fichajes (id, dia, hora, origen, tipo, usuario_id)
        VALUES ($fichaje_id, '$fecha', '$hora', 'auto_horario', 'ENTRADA', $user_id);
    "
    
    if [[ $? -eq 0 ]]; then
        log_message "INFO" "Fichaje ENTRADA auto-generado para $user_numero ($descripcion) a las $hora UTC" "$LOG_FILE"
        
        # Actualizar ultimo_fichaje en tabla usuarios
        local datetime_utc="$fecha $hora"
        TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
            UPDATE usuarios
            SET ultimo_fichaje = '$datetime_utc UTC - ENTRADA', working = 1
            WHERE id = $user_id;
        "
        
        # Actualizar hibernate_sequence
        update_hibernate_sequence $fichaje_id
        
        # Calcular e insertar estimación de horas para este día
        local dia_semana=$(get_current_day_of_week)
        local horas_estimadas=$(calculate_estimated_hours "$user_numero" "$dia_semana")
        
        if [[ $(echo "$horas_estimadas > 0" | bc -l) -eq 1 ]]; then
            insert_estimation "$user_numero" "$fecha" "$horas_estimadas" "$hora"
            log_message "INFO" "Estimación calculada para $user_numero: $horas_estimadas horas a las $hora UTC" "$LOG_FILE"
        else
            log_message "WARNING" "No se pudieron calcular horas estimadas para $user_numero" "$LOG_FILE"
        fi
        
        return 0
    else
        log_message "ERROR" "No se pudo insertar fichaje ENTRADA para usuario $user_numero" "$LOG_FILE"
        return 1
    fi
}

# =============================================================================
# FUNCIÓN PRINCIPAL DE PROCESAMIENTO
# =============================================================================
process_upcoming_schedules() {
    local fecha_actual=$(get_current_date)
    local dia_semana=$(get_current_day_of_week)
    local hora_actual=$(get_current_time)
    local hora_actual_minutos=$(time_to_minutes "$hora_actual")
    
    log_message "INFO" "Procesando horarios próximos - Fecha: $fecha_actual, Día: $dia_semana, Hora: $hora_actual UTC" "$LOG_FILE"
    
    # Obtener horarios del día actual
    local horarios=$(get_upcoming_schedules "$dia_semana" "$hora_actual_minutos" "$VENTANA_DETECCION")
    
    if [[ -z "$horarios" ]]; then
        log_message "INFO" "No hay horarios configurados para el día $dia_semana" "$LOG_FILE"
        return 0
    fi
    
    local fichajes_generados=0
    
    # Procesar cada horario
    while IFS=$'\t' read -r numero nombre_empleado hora_inicio turno_numero descripcion timezone; do
        # Saltar líneas vacías
        [[ -z "$numero" ]] && continue
        
        # Convertir hora local a UTC para logging
        local hora_inicio_utc=$(convert_local_to_utc "$hora_inicio" "$timezone" "$fecha_actual")
        
        log_message "DEBUG" "Evaluando horario - Usuario: $nombre_empleado ($numero), Horario: $hora_inicio ($timezone) → $hora_inicio_utc UTC, Turno: $turno_numero" "$LOG_FILE"
        
        # Verificar si el horario está próximo (usando timezone)
        if is_schedule_upcoming "$hora_inicio" "$timezone" "$hora_actual_minutos" "$VENTANA_DETECCION" "$fecha_actual"; then
            log_message "INFO" "Horario próximo detectado para $nombre_empleado ($numero) - Local: $hora_inicio ($timezone), UTC: $hora_inicio_utc" "$LOG_FILE"
            
            # Verificar si ya existe entrada para hoy
            local existing_entrada=$(check_existing_entrada "$numero" "$fecha_actual")
            if [[ $existing_entrada -gt 0 ]]; then
                log_message "INFO" "Ya existe entrada para $nombre_empleado en $fecha_actual. Saltando." "$LOG_FILE"
                continue
            fi
            
            # Generar hora de fichaje aleatoria (en UTC)
            local hora_fichaje=$(generate_random_entry_time "$hora_inicio" "$timezone" "$hora_actual_minutos" "$VENTANA_ALEATORIA" "$fecha_actual")
            
            # Insertar fichaje
            local desc_completa="Turno $turno_numero"
            if [[ -n "$descripcion" ]] && [[ "$descripcion" != "NULL" ]]; then
                desc_completa="$desc_completa - $descripcion"
            fi
            
            if insert_fichaje_entrada "$numero" "$fecha_actual" "$hora_fichaje" "$desc_completa"; then
                ((fichajes_generados++))
                log_message "SUCCESS" "Fichaje generado para $nombre_empleado - Horario programado: $hora_inicio ($timezone) → $hora_inicio_utc UTC, Fichaje: $hora_fichaje UTC" "$LOG_FILE"
            else
                log_message "ERROR" "Fallo al generar fichaje para $nombre_empleado" "$LOG_FILE"
            fi
        else
            local hora_inicio_utc_debug=$(convert_local_to_utc "$hora_inicio" "$timezone" "$fecha_actual")
            local hora_inicio_utc_debug_minutos=$(time_to_minutes "$hora_inicio_utc_debug")
            local diferencia_debug=$((hora_inicio_utc_debug_minutos - hora_actual_minutos))
            log_message "DEBUG" "Horario no próximo para $nombre_empleado - $hora_inicio ($timezone) → $hora_inicio_utc_debug UTC (diferencia: $diferencia_debug minutos)" "$LOG_FILE"
        fi
        
    done <<< "$horarios"
    
    log_message "INFO" "Procesamiento completado - $fichajes_generados fichajes generados" "$LOG_FILE"
    return 0
}
# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================
main() {
    local modo="$1"  # 'auto' para ejecución automática, 'manual' para testing
    
    log_message "INFO" "Iniciando script de fichaje automático basado en horarios-usuarios" "$LOG_FILE"
    
    # Mostrar información del sistema
    local current_tz=$(TZ=UTC date '+%Z %z')
    log_message "INFO" "Script ejecutándose en zona horaria: $current_tz" "$LOG_FILE"
    log_message "INFO" "Fecha/hora actual del script: $(TZ=UTC date '+%Y-%m-%d %H:%M:%S %Z')" "$LOG_FILE"
    log_message "INFO" "Día de la semana: $(get_current_day_of_week) (1=Lunes, 7=Domingo)" "$LOG_FILE"
    log_message "INFO: Zona horaria por defecto configurada: $DEFAULT_TIMEZONE"
    log_message "INFO: Configuración - Ventana detección: ${VENTANA_DETECCION}min, Ventana aleatoria: ${VENTANA_ALEATORIA}min"

    # Crear directorio de logs si no existe
    mkdir -p "$(dirname "$LOG_FILE")"

    # Procesar horarios próximos
    process_upcoming_schedules
    
    if [[ "$modo" == "manual" ]]; then
        log_message "INFO: Ejecución manual completada"
    else
        log_message "INFO: Ejecución automática completada (cron cada 5 minutos)"
    fi
}

# =============================================================================
# VERIFICACIONES INICIALES
# =============================================================================

# Verificar que mysql está instalado
if ! command -v mysql &> /dev/null; then
    log_message "ERROR: mysql cliente no está instalado"
    exit 1
fi

# Verificar que bc está instalado (para cálculos decimales)
if ! command -v bc &> /dev/null; then
    log_message "ERROR: bc (calculadora básica) no está instalado. Es necesario para cálculos de estimaciones."
    exit 1
fi

# Verificar conexión a la base de datos
if ! TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "SELECT 1;" &> /dev/null; then
    log_message "ERROR: No se puede conectar a la base de datos"
    exit 1
fi

# Verificar que existe la tabla horarios_usuario
if ! TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "DESCRIBE horarios_usuario;" &> /dev/null; then
    log_message "ERROR: La tabla horarios_usuario no existe en la base de datos"
    exit 1
fi

# =============================================================================
# PROCESAMIENTO DE ARGUMENTOS Y EJECUCIÓN
# =============================================================================

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
    echo "Configuración Cron (cada 5 minutos):"
    echo "  */5 * * * * /ruta/al/script/auto_fichaje_entrada.sh auto >> /var/log/auto_fichaje.log 2>&1"
    echo ""
    echo "Lógica del script:"
    echo "- Ejecuta cada 5 minutos via cron"
    echo "- Detecta si hay horarios de entrada en los próximos $VENTANA_DETECCION minutos"
    echo "- Genera fichaje aleatorio entre ahora y $VENTANA_ALEATORIA minutos después del horario"
    echo "- Calcula horas estimadas basado en los horarios configurados del usuario"
    echo "- Inserta estimación en tabla estimaciones para uso del script de salidas"
    echo "- No ficha si ya existe entrada para el día actual"
    echo "- Valida día de la semana según configuración en horarios_usuario"
}

# Función de testing para mostrar horarios sin fichar
test_mode() {
    local fecha_actual=$(get_current_date)
    local dia_semana=$(get_current_day_of_week)
    local hora_actual=$(get_current_time)
    
    log_message "INFO: MODO TEST - Mostrando horarios del día $dia_semana ($fecha_actual)"
    log_message "INFO: Hora actual: $hora_actual UTC"
    
    local horarios=$(get_upcoming_schedules "$dia_semana" "0" "1440")  # Todo el día
    
    if [[ -z "$horarios" ]]; then
        log_message "INFO: No hay horarios configurados para el día $dia_semana"
        return 0
    fi
    
    echo ""
    echo "HORARIOS CONFIGURADOS PARA HOY (Día $dia_semana):"
    echo "=================================================="
    printf "%-15s %-25s %-12s %-15s %-6s %-12s %-20s\n" "NÚMERO" "NOMBRE" "HORARIO" "TIMEZONE" "TURNO" "HORAS_EST" "DESCRIPCIÓN"
    echo "-------------------------------------------------------------------------------------------------------------------"
    
    while IFS=$'\t' read -r numero nombre_empleado hora_inicio turno_numero descripcion timezone; do
        [[ -z "$numero" ]] && continue
        
        # Calcular horas estimadas para este usuario
        local horas_est=$(calculate_estimated_hours "$numero" "$dia_semana")
        
        # Convertir hora local a UTC para mostrar ambas
        local hora_inicio_utc=$(convert_local_to_utc "$hora_inicio" "$timezone" "$fecha_actual")
        local horario_display="$hora_inicio→$hora_inicio_utc"
        
        printf "%-15s %-25s %-12s %-15s %-6s %-12s %-20s\n" "$numero" "$nombre_empleado" "$horario_display" "$timezone" "$turno_numero" "$horas_est" "${descripcion:-"-"}"
    done <<< "$horarios"
    
    echo ""
    echo "NOTA: HORARIO muestra formato LOCAL→UTC. HORAS_EST son las horas totales estimadas de trabajo."
    
    echo ""
}

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
    "manual")
        main "manual"
        ;;
    "auto"|"")
        main "auto"
        ;;
    *)
        echo "ERROR: Modo desconocido '$1'"
        echo "Use '$0 --help' para ver la ayuda"
        exit 1
        ;;
esac
