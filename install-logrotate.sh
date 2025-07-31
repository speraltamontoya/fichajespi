#!/bin/bash

# =============================================================================
# SCRIPT DE INSTALACIÓN DE LOGROTATE PARA FICHAJES AUTOMÁTICOS
# =============================================================================
# Este script configura logrotate en Debian 12 para gestionar los logs
# de los scripts de fichaje automático
# 
# EJECUCIÓN: sudo bash install-logrotate.sh
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   log_error "Este script debe ejecutarse como root (usa sudo)"
   exit 1
fi

log_info "=== INSTALACIÓN DE LOGROTATE PARA FICHAJES AUTOMÁTICOS ==="
echo

# Verificar que logrotate está instalado
log_step "Verificando que logrotate está instalado..."
if ! command -v logrotate &> /dev/null; then
    log_warning "logrotate no está instalado. Instalando..."
    apt update
    apt install -y logrotate
    log_info "logrotate instalado correctamente"
else
    log_info "logrotate ya está instalado"
fi

# Crear directorio de logs si no existe
log_step "Creando directorio de logs..."
LOGS_DIR="/opt/fichajes/scripts/logs"
mkdir -p "$LOGS_DIR"
chmod 755 "$LOGS_DIR"
log_info "Directorio $LOGS_DIR creado con permisos 755"

# Crear el archivo de configuración de logrotate
log_step "Creando configuración de logrotate..."
LOGROTATE_CONFIG="/etc/logrotate.d/auto-fichaje"

cat > "$LOGROTATE_CONFIG" << 'EOF'
# Configuración de logrotate para scripts de fichaje automático
/opt/fichajes/scripts/logs/auto_fichaje.log
/opt/fichajes/scripts/logs/auto_fichaje_entrada.log
/opt/fichajes/scripts/logs/auto_fichaje_salida.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
    dateext
    dateformat -%Y%m%d
    
    postrotate
        if [ -f /var/run/rsyslogd.pid ]; then
            systemctl reload rsyslog > /dev/null 2>&1 || true
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Rotación de logs de fichaje completada" >> /var/log/logrotate.log
    endscript
    
    prerotate
        mkdir -p /opt/fichajes/scripts/logs
        chmod 755 /opt/fichajes/scripts/logs
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Iniciando rotación de logs de fichaje" >> /var/log/logrotate.log
    endscript
}

# Logs de debugging
/opt/fichajes/scripts/logs/debug_*.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 0644 root root
    dateext
    dateformat -%Y%m%d
}
EOF

chmod 644 "$LOGROTATE_CONFIG"
log_info "Configuración creada en $LOGROTATE_CONFIG"

# Verificar la configuración
log_step "Verificando configuración de logrotate..."
if logrotate -d "$LOGROTATE_CONFIG"; then
    log_info "Configuración verificada correctamente"
else
    log_error "Error en la configuración de logrotate"
    exit 1
fi

# Crear archivos de log inicial si no existen
log_step "Creando archivos de log iniciales..."
for logfile in "auto_fichaje.log" "auto_fichaje_entrada.log" "auto_fichaje_salida.log"; do
    LOG_PATH="$LOGS_DIR/$logfile"
    if [[ ! -f "$LOG_PATH" ]]; then
        touch "$LOG_PATH"
        chmod 644 "$LOG_PATH"
        echo "$(date '+%Y-%m-%d %H:%M:%S UTC') [INFO] Log file created by logrotate installer" > "$LOG_PATH"
        log_info "Creado: $LOG_PATH"
    else
        log_info "Ya existe: $LOG_PATH"
    fi
done

# Verificar que logrotate está en cron
log_step "Verificando configuración de cron..."
if [[ -f /etc/cron.daily/logrotate ]]; then
    log_info "logrotate está configurado para ejecutarse diariamente"
else
    log_warning "logrotate no está en cron.daily, verificar configuración manual"
fi

# Ejecutar una rotación de prueba
log_step "Ejecutando rotación de prueba..."
if logrotate -f "$LOGROTATE_CONFIG"; then
    log_info "Rotación de prueba completada exitosamente"
else
    log_warning "Rotación de prueba falló, verificar logs"
fi

# Mostrar estado de logrotate
log_step "Mostrando estado de logrotate..."
if [[ -f /var/lib/logrotate/status ]]; then
    echo "Estado actual de logrotate:"
    grep -A 2 -B 2 "auto_fichaje" /var/lib/logrotate/status || log_info "Aún no hay entradas para auto_fichaje"
fi

echo
log_info "=== INSTALACIÓN COMPLETADA ==="
echo
echo "CONFIGURACIÓN INSTALADA:"
echo "  - Archivo de configuración: $LOGROTATE_CONFIG"
echo "  - Directorio de logs: $LOGS_DIR"
echo "  - Rotación: Diaria, mantener 30 días"
echo "  - Compresión: Sí (con delay)"
echo
echo "COMANDOS ÚTILES:"
echo "  - Verificar configuración: sudo logrotate -d $LOGROTATE_CONFIG"
echo "  - Forzar rotación: sudo logrotate -f $LOGROTATE_CONFIG"
echo "  - Ver estado: sudo cat /var/lib/logrotate/status | grep auto_fichaje"
echo "  - Ver logs de logrotate: sudo tail -f /var/log/logrotate.log"
echo
echo "PRÓXIMOS PASOS:"
echo "  1. Los logs se rotarán automáticamente cada día"
echo "  2. Los archivos antiguos se comprimirán automáticamente"
echo "  3. Se mantendrán 30 días de historial"
echo "  4. Verificar funcionamiento en 24 horas"
echo

log_info "¡Configuración de logrotate completada exitosamente!"
