#!/bin/bash

# =============================================================================
# SIMULADOR DE FICHAJES COMPLETOS PARA DÍAS PERDIDOS (UTC)
# =============================================================================
# Este script simula fichajes completos de entrada y salida para usuarios
# específicos siguiendo patrones de trabajo con múltiples tramos.
# PROPÓSITO: Completar días que no se ficharon por problemas del servidor.
# IMPORTANTE: Trabaja en UTC para consistencia con la base de datos.
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
# CONFIGURACIÓN POR USUARIO
# =============================================================================
# Formato: "codigo_usuario:num_tramos:horas_diarias:entrada1_min_h:entrada1_min_m:entrada1_max_h:entrada1_max_m:entrada2_min_h:entrada2_min_m:entrada2_max_h:entrada2_max_m:nombre"

declare -A CONFIGURACION_USUARIOS
CONFIGURACION_USUARIOS["fichajesPi000"]="2:8:11:55:12:15:19:55:20:15:AdminFichajesPi"
CONFIGURACION_USUARIOS["4086855489"]="2:4:12:55:13:15:20:55:21:15:Santiago"
CONFIGURACION_USUARIOS["1234567890"]="2:8:13:55:14:15:19:55:20:15:TestUser"

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

# Función para generar número aleatorio entre min y max
random_between() {
    local min=$1
    local max=$2
    echo $((RANDOM % (max - min + 1) + min))
}

# Función para verificar si una fecha es lunes o domingo
is_weekend() {
    local fecha="$1"
    local day_of_week=$(TZ=UTC date -d "$fecha" '+%u')
    # 1=Lunes, 7=Domingo
    if [[ $day_of_week -eq 1 ]] || [[ $day_of_week -eq 7 ]]; then
        return 0  # es fin de semana
    else
        return 1  # no es fin de semana
    fi
}

# Función para verificar si ya existen fichajes para una fecha específica
check_existing_fichajes() {
    local user_numero="$1"
    local fecha="$2"  # formato YYYY-MM-DD
    
    local count=$(TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "
        SELECT COUNT(*) FROM fichajes 
        WHERE usuario_id = (SELECT id FROM usuarios WHERE numero = '$user_numero')
        AND dia = '$fecha'
    " 2>/dev/null)
    
    echo "${count:-0}"
}

# Función para calcular tiempo trabajado en la semana
calculate_weekly_hours() {
    local user_numero="$1"
    local fecha="$2"  # formato YYYY-MM-DD
    
    # Calcular el lunes de la semana
    local lunes=$(TZ=UTC date -d "$fecha -$(TZ=UTC date -d "$fecha" '+%u') days +1 day" '+%Y-%m-%d')
    local domingo=$(TZ=UTC date -d "$lunes +6 days" '+%Y-%m-%d')
    
    log_message "DEBUG" "Calculando horas semanales para usuario $user_numero entre $lunes y $domingo" "$LOG_FILE"
    
    # Obtener fichajes de entrada y salida de la semana
    local query="
        SELECT dia, hora, tipo FROM fichajes 
        WHERE usuario_id = (SELECT id FROM usuarios WHERE numero = '$user_numero')
        AND dia BETWEEN '$lunes' AND '$domingo'
        ORDER BY dia, hora
    "
    
    local total_minutes=0
    local entrada_actual=""
    
    while read -r dia hora tipo; do
        if [[ "$tipo" == "ENTRADA" ]]; then
            entrada_actual="$dia $hora"
        elif [[ "$tipo" == "SALIDA" ]] && [[ -n "$entrada_actual" ]]; then
            local salida_actual="$dia $hora"
            local entrada_timestamp=$(TZ=UTC date -d "$entrada_actual" +%s)
            local salida_timestamp=$(TZ=UTC date -d "$salida_actual" +%s)
            local diff_minutes=$(( (salida_timestamp - entrada_timestamp) / 60 ))
            total_minutes=$((total_minutes + diff_minutes))
            entrada_actual=""
        fi
    done < <(TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "$query" 2>/dev/null)
    
    local total_hours=$(echo "scale=2; $total_minutes / 60" | bc)
    log_message "DEBUG" "Total horas trabajadas en la semana: $total_hours" "$LOG_FILE"
    echo "$total_hours"
}

# Función para insertar fichaje
insert_fichaje() {
    local user_numero="$1"
    local fecha="$2"
    local hora="$3"
    local tipo="$4"
    
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
    
    # Insertar fichaje
    TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
        INSERT INTO fichajes (id, dia, hora, origen, tipo, usuario_id)
        VALUES ($fichaje_id, '$fecha', '$hora', 'auto', '$tipo', $user_id);
    "
    
    if [[ $? -eq 0 ]]; then
        log_message "INFO" "Fichaje $tipo insertado para usuario $user_numero (ID: $fichaje_id) a las $hora UTC" "$LOG_FILE"
        
        # Actualizar ultimo_fichaje en tabla usuarios
        local datetime_utc="$fecha $hora"
        TZ=UTC mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "
            UPDATE usuarios
            SET ultimo_fichaje = '$datetime_utc UTC - $tipo', working = $(if [[ "$tipo" == "ENTRADA" ]]; then echo "1"; else echo "0"; fi)
            WHERE id = $user_id;
        "
        
        # Actualizar hibernate_sequence
        update_hibernate_sequence $fichaje_id
        return 0
    else
        log_message "ERROR" "No se pudo insertar fichaje $tipo para usuario $user_numero" "$LOG_FILE"
        return 1
    fi
}

# Función para generar fichajes para un usuario en una fecha específica
generate_fichajes_for_user() {
    local user_numero="$1"
    local fecha="$2"  # formato YYYY-MM-DD
    local fecha_param="$3"  # opcional, si viene de parámetro
    
    # Verificar si el usuario tiene configuración
    if [[ -z "${CONFIGURACION_USUARIOS[$user_numero]}" ]]; then
        log_message "ERROR: No hay configuración para el usuario $user_numero"
        return 1
    fi
    
    # Parsear configuración
    local config="${CONFIGURACION_USUARIOS[$user_numero]}"
    IFS=':' read -r num_tramos horas_diarias entrada1_min_h entrada1_min_m entrada1_max_h entrada1_max_m entrada2_min_h entrada2_min_m entrada2_max_h entrada2_max_m nombre <<< "$config"
    IFS=$' \t\n'  # Resetear IFS al valor por defecto
    
    log_message "INFO: Procesando fichajes para $nombre ($user_numero) - Fecha: $fecha"
    
    # Si no viene de parámetro, verificar que no sea fin de semana
    if [[ -z "$fecha_param" ]] && is_weekend "$fecha"; then
        log_message "INFO: $fecha es lunes o domingo. No se ficha automáticamente."
        return 0
    fi
    
    # Verificar fichajes existentes
    local existing=$(check_existing_fichajes "$user_numero" "$fecha")
    if [[ $existing -gt 0 ]]; then
        log_message "INFO: Ya existen $existing fichajes para $nombre en $fecha. No se registra nuevamente."
        return 0
    fi
    
    # Verificar límite semanal
    local horas_semanales=$(calculate_weekly_hours "$user_numero" "$fecha")
    local limite_semanal=$(echo "$horas_diarias * 5 + 1" | bc)  # margen de 1 hora
    
    if [[ $(awk "BEGIN {print ($horas_semanales >= $limite_semanal)}" 2>/dev/null) -eq 1 ]]; then
        log_message "INFO: Ya se han registrado ${limite_semanal}h esta semana para $nombre. No se añaden más fichajes."
        return 0
    fi
    
    # Generar duración de tramos
    local horas_diarias_min=$(echo "$horas_diarias - 0.5" | bc)
    local horas_diarias_max=$(echo "$horas_diarias + 0.5" | bc)
    local min_tramo_min=$(echo "scale=0; ($horas_diarias / $num_tramos - 1) * 60" | bc)
    local max_tramo_min=$(echo "scale=0; ($horas_diarias / $num_tramos + 1) * 60" | bc)
    
    # Convertir a enteros
    min_tramo_min=${min_tramo_min%.*}
    max_tramo_min=${max_tramo_min%.*}
    
    # Generar tramos válidos
    local tramos=()
    local intentos=0
    while [[ ${#tramos[@]} -eq 0 && $intentos -lt 100 ]]; do
        local tramo1=$(random_between $min_tramo_min $max_tramo_min)
        local tramo2=$(random_between $min_tramo_min $max_tramo_min)
        local total_min=$((tramo1 + tramo2))
        local total_hours=$(echo "scale=2; $total_min / 60" | bc)
        
        if [[ $(awk "BEGIN {print ($total_hours >= $horas_diarias_min && $total_hours <= $horas_diarias_max)}" 2>/dev/null) -eq 1 ]]; then
            tramos=($tramo1 $tramo2)
        fi
        intentos=$((intentos + 1))
    done
    
    if [[ ${#tramos[@]} -eq 0 ]]; then
        log_message "ERROR: No se pudieron generar tramos válidos para $nombre"
        return 1
    fi
    
    log_message "DEBUG: Tramos generados: ${tramos[*]} minutos (Total: $(echo "scale=2; (${tramos[0]} + ${tramos[1]}) / 60" | bc)h)"
    
    # Generar fichajes para cada tramo
    local eventos=()
    
    # Tramo 1
    local entrada1_min_total=$((entrada1_min_h * 3600 + entrada1_min_m * 60))
    local entrada1_max_total=$((entrada1_max_h * 3600 + entrada1_max_m * 60))
    local entrada1_random=$(random_between $entrada1_min_total $entrada1_max_total)
    local entrada1_hora=$(printf "%02d:%02d:%02d" $((entrada1_random / 3600)) $(((entrada1_random % 3600) / 60)) $((entrada1_random % 60)))
    
    local duracion1_extra=$(random_between 0 59)
    local salida1_total=$((entrada1_random + ${tramos[0]} * 60 + duracion1_extra))
    
    # Si salida1 supera las 24h, ajustar para el día siguiente
    if [[ $salida1_total -ge 86400 ]]; then
        salida1_total=$((salida1_total - 86400))
        local fecha_salida1=$(TZ=UTC date -d "$fecha +1 day" '+%Y-%m-%d')
        local salida1_hora=$(printf "%02d:%02d:%02d" $((salida1_total / 3600)) $(((salida1_total % 3600) / 60)) $((salida1_total % 60)))
        eventos+=("$fecha|$entrada1_hora|ENTRADA")
        eventos+=("$fecha_salida1|$salida1_hora|SALIDA")
    else
        local salida1_hora=$(printf "%02d:%02d:%02d" $((salida1_total / 3600)) $(((salida1_total % 3600) / 60)) $((salida1_total % 60)))
        eventos+=("$fecha|$entrada1_hora|ENTRADA")
        eventos+=("$fecha|$salida1_hora|SALIDA")
    fi
    
    # Tramo 2
    local entrada2_min_total=$((entrada2_min_h * 3600 + entrada2_min_m * 60))
    local entrada2_max_total=$((entrada2_max_h * 3600 + entrada2_max_m * 60))
    local entrada2_random=$(random_between $entrada2_min_total $entrada2_max_total)
    local entrada2_hora=$(printf "%02d:%02d:%02d" $((entrada2_random / 3600)) $(((entrada2_random % 3600) / 60)) $((entrada2_random % 60)))
    
    local duracion2_extra=$(random_between 0 59)
    local salida2_total=$((entrada2_random + ${tramos[1]} * 60 + duracion2_extra))
    
    # Si salida2 supera las 24h, ajustar para el día siguiente
    if [[ $salida2_total -ge 86400 ]]; then
        salida2_total=$((salida2_total - 86400))
        local fecha_salida2=$(TZ=UTC date -d "$fecha +1 day" '+%Y-%m-%d')
        local salida2_hora=$(printf "%02d:%02d:%02d" $((salida2_total / 3600)) $(((salida2_total % 3600) / 60)) $((salida2_total % 60)))
        eventos+=("$fecha|$entrada2_hora|ENTRADA")
        eventos+=("$fecha_salida2|$salida2_hora|SALIDA")
    else
        local salida2_hora=$(printf "%02d:%02d:%02d" $((salida2_total / 3600)) $(((salida2_total % 3600) / 60)) $((salida2_total % 60)))
        eventos+=("$fecha|$entrada2_hora|ENTRADA")
        eventos+=("$fecha|$salida2_hora|SALIDA")
    fi
    
    # Insertar fichajes
    local fichajes_insertados=0
    for evento in "${eventos[@]}"; do
        IFS='|' read -r evento_fecha evento_hora_completa evento_tipo <<< "$evento"
        # evento_hora_completa viene en formato HH:MM:SS, lo parseamos correctamente
        if insert_fichaje "$user_numero" "$evento_fecha" "$evento_hora_completa" "$evento_tipo"; then
            fichajes_insertados=$((fichajes_insertados + 1))
        fi
    done
    
    log_message "INFO: $fichajes_insertados fichajes registrados para $nombre en $fecha"
    return 0
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================
main() {
    local target_date="$1"
    local specific_user="$2"
    
    log_message "INFO: Iniciando simulador de fichajes completos"
    
    # Mostrar zona horaria actual del script
    local current_tz=$(TZ=UTC date '+%Z %z')
    log_message "INFO: Script ejecutándose en zona horaria: $current_tz"
    log_message "INFO: Fecha/hora actual del script: $(TZ=UTC date '+%Y-%m-%d %H:%M:%S %Z')"

    # Crear directorio de logs si no existe
    mkdir -p "$(dirname "$LOG_FILE")"

    # Determinar fecha objetivo
    if [[ -n "$target_date" ]]; then
        # Validar formato de fecha
        if ! TZ=UTC date -d "$target_date" '+%Y-%m-%d' &>/dev/null; then
            log_message "ERROR: Formato de fecha inválido: $target_date. Use YYYY-MM-DD"
            return 1
        fi
        local fecha_objetivo="$target_date"
        log_message "INFO: Procesando fecha específica: $fecha_objetivo"
    else
        local fecha_objetivo=$(TZ=UTC date '+%Y-%m-%d')
        log_message "INFO: Procesando fecha actual: $fecha_objetivo"
    fi
    
    # Procesar usuarios
    if [[ -n "$specific_user" ]]; then
        # Usuario específico
        if [[ -n "${CONFIGURACION_USUARIOS[$specific_user]}" ]]; then
            generate_fichajes_for_user "$specific_user" "$fecha_objetivo" "$target_date"
        else
            log_message "ERROR: Usuario $specific_user no encontrado en configuración"
            return 1
        fi
    else
        # Todos los usuarios configurados
        for user_numero in "${!CONFIGURACION_USUARIOS[@]}"; do
            generate_fichajes_for_user "$user_numero" "$fecha_objetivo" "$target_date"
        done
    fi
    
    log_message "INFO: Simulador de fichajes completos completado"
}

# =============================================================================
# VERIFICACIONES INICIALES
# =============================================================================

# Verificar que bc está instalado
if ! command -v bc &> /dev/null; then
    log_message "ERROR: bc no está instalado. Instálalo con: sudo apt-get install bc"
    exit 1
fi

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

# Función de ayuda
show_help() {
    echo "Uso: $0 [FECHA] [USUARIO]"
    echo ""
    echo "FECHA    - Fecha específica en formato YYYY-MM-DD (opcional, por defecto hoy)"
    echo "USUARIO  - Código específico del usuario (opcional, por defecto todos)"
    echo ""
    echo "Ejemplos:"
    echo "  $0                           # Procesar todos los usuarios para hoy"
    echo "  $0 2025-07-30               # Procesar todos los usuarios para fecha específica"
    echo "  $0 2025-07-30 fichajesPi000 # Procesar usuario específico para fecha específica"
    echo "  $0 '' fichajesPi000         # Procesar usuario específico para hoy"
    echo ""
    echo "Usuarios configurados:"
    for user in "${!CONFIGURACION_USUARIOS[@]}"; do
        IFS=':' read -r num_tramos horas_diarias entrada1_min_h entrada1_min_m entrada1_max_h entrada1_max_m entrada2_min_h entrada2_min_m entrada2_max_h entrada2_max_m nombre <<< "${CONFIGURACION_USUARIOS[$user]}"
        IFS=$' \t\n'  # Resetear IFS al valor por defecto
        echo "  $user - $nombre ($horas_diarias horas, $num_tramos tramos)"
    done
}

# Procesar argumentos
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================
main "$1" "$2"
