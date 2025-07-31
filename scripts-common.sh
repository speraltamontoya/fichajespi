#!/bin/bash

# =============================================================================
# FUNCIONES COMUNES PARA CARGA DE CONFIGURACIÓN
# =============================================================================
# Este archivo contiene funciones reutilizables para cargar configuración
# desde el archivo scripts-config.properties
# =============================================================================

# Función para cargar configuración desde archivo de propiedades
load_config() {
    local config_file="${1:-scripts-config.properties}"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    local config_path="$script_dir/$config_file"
    
    # Verificar si existe el archivo de configuración
    if [[ ! -f "$config_path" ]]; then
        echo "ERROR: Archivo de configuración no encontrado: $config_path"
        echo "AYUDA: Copia 'example-scripts-config.properties' como 'scripts-config.properties' y configúralo"
        exit 1
    fi
    
    # Cargar configuración (ignorar comentarios y líneas vacías)
    while IFS='=' read -r key value; do
        # Ignorar comentarios y líneas vacías
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # Remover espacios en blanco alrededor de key y value
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Exportar variable
        if [[ -n "$key" ]] && [[ -n "$value" ]]; then
            export "$key"="$value"
        fi
    done < "$config_path"
    
    echo "INFO: Configuración cargada desde $config_path"
}

# Función para validar configuración de base de datos
validate_db_config() {
    local required_vars=("DB_HOST" "DB_PORT" "DB_NAME" "DB_USER" "DB_PASSWORD")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "ERROR: Variables de base de datos faltantes: ${missing_vars[*]}"
        echo "AYUDA: Verifica tu archivo scripts-config.properties"
        exit 1
    fi
    
    echo "INFO: Configuración de base de datos validada correctamente"
}

# Función para verificar conectividad a la base de datos
test_db_connection() {
    echo "INFO: Verificando conexión a base de datos..."
    
    if ! command -v mysql &> /dev/null; then
        echo "ERROR: mysql cliente no está instalado"
        return 1
    fi
    
    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "SELECT 1;" &> /dev/null; then
        echo "INFO: Conexión a base de datos exitosa"
        return 0
    else
        echo "ERROR: No se puede conectar a la base de datos"
        echo "DEBUG: Host=$DB_HOST, Port=$DB_PORT, DB=$DB_NAME, User=$DB_USER"
        return 1
    fi
}

# Función para crear directorio de logs si no existe
setup_logging() {
    local log_dir="${LOG_DIR:-./logs}"
    
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
        echo "INFO: Directorio de logs creado: $log_dir"
    fi
    
    # Exportar LOG_DIR para uso en otros scripts
    export LOG_DIR="$log_dir"
}

# Función para escribir logs con timestamp
log_message() {
    local level="${1:-INFO}"
    local message="$2"
    local log_file="${3:-$LOG_FILE}"
    local timestamp=$(TZ=UTC date '+%Y-%m-%d %H:%M:%S UTC')
    
    local log_entry="[$timestamp] [$level] $message"
    
    # Escribir a archivo de log si está definido
    if [[ -n "$log_file" ]] && [[ -n "$message" ]]; then
        echo "$log_entry" | tee -a "$log_file"
    else
        echo "$log_entry"
    fi
}

# Función para inicializar configuración común
init_script_config() {
    local script_name="${1:-$(basename "$0")}"
    
    # Cargar configuración
    load_config
    
    # Validar configuración de DB
    validate_db_config
    
    # Configurar logging
    setup_logging
    
    # Definir archivo de log específico del script si no está definido
    if [[ -z "$LOG_FILE" ]]; then
        export LOG_FILE="$LOG_DIR/${script_name%.*}.log"
    fi
    
    # Configurar zona horaria UTC para consistencia
    export TZ=UTC
    
    # Log de inicio
    log_message "INFO" "=== Iniciando $script_name ===" "$LOG_FILE"
    log_message "INFO" "Configuración cargada - DB: $DB_HOST:$DB_PORT/$DB_NAME" "$LOG_FILE"
    
    # Verificar conexión a DB
    if ! test_db_connection; then
        log_message "ERROR" "Fallo en conexión a base de datos" "$LOG_FILE"
        exit 1
    fi
}

# Función para verificar herramientas requeridas
check_required_tools() {
    local tools=("mysql" "bc")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_message "ERROR" "Herramientas faltantes: ${missing_tools[*]}" "$LOG_FILE"
        exit 1
    fi
}

# Función para cleanup al finalizar script
cleanup_script() {
    local script_name="${1:-$(basename "$0")}"
    log_message "INFO" "=== Finalizando $script_name ===" "$LOG_FILE"
}
