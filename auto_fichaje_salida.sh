#!/bin/bash

# =============================================================================
# SCRIPT DE FICHAJE AUTOMÁTICO DE SALIDA CON ESTIMACIONES (UTC)
# =============================================================================
# Este script revisa los empleados que han fichado entrada y verifica si
# tienen estimación de tiempo. Si ha pasado suficiente tiempo según la
# estimación + la tolerancia configurada, registra automáticamente la salida.
# Se ejecuta cada 5 minutos vía cron.
# IMPORTANTE: Trabaja en UTC para consistencia con la base de datos.
# La tolerancia es configurable en scripts-config.properties (TOLERANCE_HOURS)
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

# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

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

# Función para convertir horas a segundos
hours_to_seconds() {
    local hours="$1"
    local seconds=$(echo "scale=0; $hours * 3600 / 1" | bc)
    echo $seconds
}

# Función para generar tiempo aleatorio (0-5 minutos en segundos)
get_random_minutes() {
    echo $((RANDOM % 300))
}

# Función para calcular timestamp de salida real (sin tolerancia)
calculate_auto_exit_time() {
    local entry_datetime="$1"
    local estimation_hours="$2"
    
    # Validar que estimation_hours es un número válido
    if [[ -z "$estimation_hours" ]] || [[ "$estimation_hours" == "." ]]; then
        estimation_hours="$DEFAULT_ESTIMATION_HOURS"
    fi
    
    # Convertir datetime de entrada a timestamp
    local entry_timestamp=$(TZ=UTC date -d "$entry_datetime" +%s 2>/dev/null)
    
    if [[ -z "$entry_timestamp" ]]; then
        log_message "ERROR" "No se pudo convertir datetime de entrada: $entry_datetime" "$LOG_FILE"
        return 1
    fi
    
    # Calcular segundos de estimación (SIN tolerancia para la hora de salida)
    local estimation_seconds=$(hours_to_seconds "$estimation_hours")
    
    # Agregar tiempo aleatorio (0-5 minutos)
    local random_seconds=$(get_random_minutes)
    
    # Calcular timestamp de salida: entrada + estimación + random (SIN tolerancia)
    local exit_timestamp=$((entry_timestamp + estimation_seconds + random_seconds))
    
    echo $exit_timestamp
}

# Función para calcular cuándo debe ejecutarse la salida automática (con tolerancia)
calculate_trigger_time() {
    local entry_datetime="$1"
    local estimation_hours="$2"
    
    # Convertir datetime de entrada a timestamp
    local entry_timestamp=$(TZ=UTC date -d "$entry_datetime" +%s 2>/dev/null)
    
    if [[ -z "$entry_timestamp" ]]; then
        log_message "ERROR" "No se pudo convertir datetime de entrada: $entry_datetime" "$LOG_FILE"
        return 1
    fi
    
    # Calcular segundos de estimación + tolerancia
    local estimation_seconds=$(hours_to_seconds "$estimation_hours")
    local tolerance_seconds=$(hours_to_seconds "$TOLERANCE_HOURS")
    
    # Calcular timestamp trigger: entrada + estimación + tolerancia
    local trigger_timestamp=$((entry_timestamp + estimation_seconds + tolerance_seconds))
    
    echo $trigger_timestamp
}

# Función para insertar fichaje de salida automática
insert_auto_exit_fichaje() {
    local user_id="$1"
    local fichaje_id="$2"
    local exit_timestamp="$3"
    
    # Validar que el timestamp es válido
    if [[ -z "$exit_timestamp" ]] || [[ "$exit_timestamp" == "0" ]]; then
        log_message "ERROR" "Timestamp de salida inválido: $exit_timestamp" "$LOG_FILE"
        return 1
    fi
    
    # Convertir timestamp a fecha y hora en UTC
    local exit_date=$(TZ=UTC date -d "@$exit_timestamp" '+%Y-%m-%d' 2>/dev/null)
    local exit_time=$(TZ=UTC date -d "@$exit_timestamp" '+%H:%M:%S' 2>/dev/null)
    local exit_datetime=$(TZ=UTC date -d "@$exit_timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)

    # Validar que las conversiones de fecha fueron exitosas
    if [[ -z "$exit_date" ]] || [[ -z "$exit_time" ]] || [[ -z "$exit_datetime" ]]; then
        log_message "ERROR" "No se pudo convertir timestamp $exit_timestamp a fecha/hora" "$LOG_FILE"
        return 1
    fi

    log_message "DEBUG" "Insertando fichaje - Fecha: $exit_date, Hora: $exit_time" "$LOG_FILE"

    # Insertar fichaje en la tabla fichajes (forzar UTC)
    TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
        INSERT INTO fichajes (id, dia, hora, origen, tipo, usuario_id)
        VALUES ($fichaje_id, '$exit_date', '$exit_time', 'auto', 'SALIDA', $user_id);
    "

    if [[ $? -eq 0 ]]; then
        log_message "INFO" "Fichaje de salida automática insertado para usuario $user_id (ID: $fichaje_id) a las $exit_time UTC" "$LOG_FILE"

        # Actualizar ultimo_fichaje en tabla usuarios (forzar UTC)
        TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
            UPDATE usuarios
            SET ultimo_fichaje = '$exit_datetime UTC - SALIDA', working = 0
            WHERE id = $user_id;
        "

        if [[ $? -eq 0 ]]; then
            log_message "INFO" "Campo ultimo_fichaje actualizado para usuario $user_id" "$LOG_FILE"
        else
            log_message "ERROR" "No se pudo actualizar ultimo_fichaje para usuario $user_id" "$LOG_FILE"
        fi

        # Actualizar hibernate_sequence
        update_hibernate_sequence $fichaje_id

    else
        log_message "ERROR" "No se pudo insertar fichaje de salida automática para usuario $user_id" "$LOG_FILE"
    fi
}

# Función para obtener estimación de un usuario para una fecha específica
get_user_estimation() {
    local user_id="$1"
    local user_numero="$2"
    local entry_datetime="$3"
    
    # Extraer solo la fecha del datetime de entrada
    local entry_date=$(echo "$entry_datetime" | cut -d' ' -f1)
    
    # Buscar estimación en la tabla estimaciones
    # NOTA: el campo es usuario_id (no usuario_numero) y contiene el número del usuario
    local estimation_query="
        SELECT horas_estimadas
        FROM estimaciones
        WHERE usuario_id = $user_numero
        AND DATE(fecha) = '$entry_date'
        ORDER BY fecha DESC
        LIMIT 1
    "
    
    {
        local estimation=$(TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "$estimation_query" 2>/dev/null)
        
        if [[ -n "$estimation" ]]; then
            # Limpiar la estimación de cualquier carácter no numérico (excepto punto decimal)
            estimation=$(echo "$estimation" | sed 's/[^0-9.]//g')
            if [[ -z "$estimation" ]] || [[ "$estimation" == "." ]]; then
                estimation="$DEFAULT_ESTIMATION_HOURS"
            fi
            echo "DEBUG: Estimación encontrada para usuario $user_numero: $estimation horas" >&2
            echo "$estimation"
        else
            echo "DEBUG: No se encontró estimación para usuario $user_numero en fecha $entry_date, usando valor por defecto: $DEFAULT_ESTIMATION_HOURS" >&2
            echo "$DEFAULT_ESTIMATION_HOURS"
        fi
    } 2>> "$LOG_FILE"
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================
main() {
    log_message "INFO" "Iniciando script de fichaje automático con estimaciones" "$LOG_FILE"
    
    # Mostrar zona horaria actual del script
    local current_tz=$(TZ=UTC date '+%Z %z')
    log_message "INFO" "Script ejecutándose en zona horaria: $current_tz" "$LOG_FILE"
    log_message "INFO" "Fecha/hora actual del script: $(TZ=UTC date '+%Y-%m-%d %H:%M:%S %Z')" "$LOG_FILE"

    # Crear directorio de logs si no existe
    mkdir -p "$(dirname "$LOG_FILE")"

    # Obtener timestamp actual (forzar UTC)
    local current_timestamp=$(TZ=UTC date +%s)

    # Buscar empleados que han fichado entrada y están trabajando
    local query="
        SELECT u.id, u.numero, u.nombre_empleado, u.ultimo_fichaje
        FROM usuarios u
        WHERE u.working = 1
        AND u.de_baja = 0
        AND u.ultimo_fichaje LIKE '%ENTRADA%'
    "

    # Ejecutar consulta y procesar resultados (forzar UTC en MySQL)
    TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "$query" | while read -r user_id user_numero nombre_empleado ultimo_fichaje; do

        log_message "DEBUG" "Procesando usuario $user_id ($nombre_empleado) - Número: $user_numero" "$LOG_FILE"
        log_message "DEBUG" "Último fichaje: $ultimo_fichaje" "$LOG_FILE"

        # Extraer datetime de entrada del último fichaje
        local entry_datetime=$(echo "$ultimo_fichaje" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}')

        if [[ -z "$entry_datetime" ]]; then
            log_message "ERROR" "No se pudo extraer datetime de entrada para usuario $user_id" "$LOG_FILE"
            log_message "DEBUG" "Texto del último fichaje: '$ultimo_fichaje'" "$LOG_FILE"
            continue
        fi

        log_message "DEBUG" "Datetime de entrada extraído: $entry_datetime" "$LOG_FILE"

        # Obtener estimación para este usuario y fecha
        local estimation_hours=$(get_user_estimation "$user_id" "$user_numero" "$entry_datetime" 2>>"$LOG_FILE")
        
        # Limpiar la estimación de cualquier texto extra que pueda quedar
        # Permitir números decimales con punto
        estimation_hours=$(echo "$estimation_hours" | grep -oE '^[0-9]+\.?[0-9]*' | head -1)
        
        # Validar que tenemos una estimación válida
        if [[ -z "$estimation_hours" ]] || [[ "$estimation_hours" == "." ]]; then
            estimation_hours="$DEFAULT_ESTIMATION_HOURS"
        fi
        
        log_message "DEBUG" "Estimación limpia obtenida: $estimation_hours horas" "$LOG_FILE"

        # Calcular timestamp de entrada
        local entry_timestamp=$(TZ=UTC date -d "$entry_datetime" +%s)
        
        # Calcular cuando debería registrarse la salida automática (hora real de salida)
        local auto_exit_timestamp=$(calculate_auto_exit_time "$entry_datetime" "$estimation_hours")
        
        # Calcular cuándo debe ejecutarse el trigger (con tolerancia)
        local trigger_timestamp=$(calculate_trigger_time "$entry_datetime" "$estimation_hours")
        
        # Verificar que obtuvimos timestamps válidos
        if [[ -z "$auto_exit_timestamp" ]] || [[ "$auto_exit_timestamp" == "0" ]] || [[ -z "$trigger_timestamp" ]] || [[ "$trigger_timestamp" == "0" ]]; then
            log_message "ERROR" "No se pudo calcular timestamps para usuario $user_id" "$LOG_FILE"
            continue
        fi
        
        # Verificar si ya es tiempo de registrar salida automática (usando trigger_timestamp)
        if [[ $current_timestamp -ge $trigger_timestamp ]]; then
            
            # Verificar que no hay ya un fichaje de salida posterior a la entrada
            local check_exit_query="
                SELECT COUNT(*) FROM fichajes
                WHERE usuario_id = $user_id
                AND tipo = 'SALIDA'
                AND CONCAT(dia, ' ', hora) > '$entry_datetime'
            "
            local existing_exit=$(TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "$check_exit_query")

            if [[ $existing_exit -gt 0 ]]; then
                log_message "INFO" "Ya existe fichaje de salida posterior para $nombre_empleado (ID: $user_id)" "$LOG_FILE"
                continue
            fi

            log_message "INFO" "Es hora de registrar salida automática para $nombre_empleado (ID: $user_id)" "$LOG_FILE"
            log_message "INFO" "Entrada: $entry_datetime, Estimación: $estimation_hours horas" "$LOG_FILE"

            # Obtener siguiente ID para el fichaje
            local next_id=$(get_next_id)

            # Insertar fichaje de salida automática
            insert_auto_exit_fichaje "$user_id" "$next_id" "$auto_exit_timestamp"

        else
            local next_trigger_time=$(TZ=UTC date -d "@$trigger_timestamp" '+%Y-%m-%d %H:%M:%S')
            local exit_time=$(TZ=UTC date -d "@$auto_exit_timestamp" '+%Y-%m-%d %H:%M:%S')
            log_message "DEBUG" "Aún no es hora para $nombre_empleado - Trigger: $next_trigger_time UTC, Salida programada: $exit_time UTC" "$LOG_FILE"
        fi

    done

    log_message "INFO" "Script de fichaje automático de salida completado" "$LOG_FILE"
}

# =============================================================================
# VERIFICACIONES PREVIAS Y EJECUCIÓN
# =============================================================================

# Verificar que bc está instalado
if ! command -v bc &> /dev/null; then
    log_message "ERROR" "bc no está instalado. Instálalo con: sudo apt-get install bc" "$LOG_FILE"
    exit 1
fi

# Verificar que mysql cliente está instalado
if ! command -v mysql &> /dev/null; then
    log_message "ERROR" "mysql cliente no está instalado" "$LOG_FILE"
    exit 1
fi

# Verificar conexión a base de datos
if ! test_db_connection; then
    log_message "ERROR" "No se puede conectar a la base de datos" "$LOG_FILE"
    exit 1
fi

# Ejecutar función principal
main "$@"