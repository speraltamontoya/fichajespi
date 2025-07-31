#!/bin/bash

# =============================================================================
# SCRIPT DE VERIFICACIÓN DE LOGROTATE PARA FICHAJES AUTOMÁTICOS
# =============================================================================
# Este script verifica que logrotate esté configurado y funcionando correctamente
# para los logs de los scripts de fichaje automático
# 
# EJECUCIÓN: bash verify-logrotate.sh
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuración
LOGS_DIR="/opt/fichajes/scripts/logs"
LOGROTATE_CONFIG="/etc/logrotate.d/auto-fichaje"
LOG_FILES=(
    "auto_fichaje.log"
    "auto_fichaje_entrada.log"
    "auto_fichaje_salida.log"
)

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
    echo -e "${BLUE}[CHECK]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Función para verificar si comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "================================================="
echo "VERIFICACIÓN DE LOGROTATE PARA FICHAJES AUTOMÁTICOS"
echo "================================================="
echo

# 1. Verificar que logrotate está instalado
log_step "Verificando instalación de logrotate..."
if command_exists logrotate; then
    LOGROTATE_VERSION=$(logrotate --version | head -n1)
    log_ok "logrotate está instalado: $LOGROTATE_VERSION"
else
    log_fail "logrotate no está instalado"
    echo "  Instalar con: sudo apt install logrotate"
    exit 1
fi

# 2. Verificar configuración de logrotate
log_step "Verificando configuración de logrotate..."
if [[ -f "$LOGROTATE_CONFIG" ]]; then
    log_ok "Archivo de configuración existe: $LOGROTATE_CONFIG"
    
    # Verificar permisos
    PERMS=$(stat -c "%a" "$LOGROTATE_CONFIG")
    if [[ "$PERMS" == "644" ]]; then
        log_ok "Permisos correctos: $PERMS"
    else
        log_warning "Permisos incorrectos: $PERMS (debería ser 644)"
    fi
    
    # Verificar propietario
    OWNER=$(stat -c "%U:%G" "$LOGROTATE_CONFIG")
    if [[ "$OWNER" == "root:root" ]]; then
        log_ok "Propietario correcto: $OWNER"
    else
        log_warning "Propietario incorrecto: $OWNER (debería ser root:root)"
    fi
else
    log_fail "Archivo de configuración no existe: $LOGROTATE_CONFIG"
    echo "  Ejecutar: sudo bash install-logrotate.sh"
    exit 1
fi

# 3. Verificar sintaxis de configuración
log_step "Verificando sintaxis de configuración..."
if sudo logrotate -d "$LOGROTATE_CONFIG" >/dev/null 2>&1; then
    log_ok "Sintaxis de configuración correcta"
else
    log_fail "Error en sintaxis de configuración"
    echo "  Verificar con: sudo logrotate -d $LOGROTATE_CONFIG"
    exit 1
fi

# 4. Verificar directorio de logs
log_step "Verificando directorio de logs..."
if [[ -d "$LOGS_DIR" ]]; then
    log_ok "Directorio de logs existe: $LOGS_DIR"
    
    # Verificar permisos del directorio
    DIR_PERMS=$(stat -c "%a" "$LOGS_DIR")
    if [[ "$DIR_PERMS" == "755" ]]; then
        log_ok "Permisos del directorio correctos: $DIR_PERMS"
    else
        log_warning "Permisos del directorio: $DIR_PERMS (recomendado: 755)"
    fi
else
    log_warning "Directorio de logs no existe: $LOGS_DIR"
    echo "  Crear con: sudo mkdir -p $LOGS_DIR && sudo chmod 755 $LOGS_DIR"
fi

# 5. Verificar archivos de logs
log_step "Verificando archivos de logs..."
for logfile in "${LOG_FILES[@]}"; do
    LOG_PATH="$LOGS_DIR/$logfile"
    if [[ -f "$LOG_PATH" ]]; then
        SIZE=$(du -h "$LOG_PATH" | cut -f1)
        LINES=$(wc -l < "$LOG_PATH" 2>/dev/null || echo "0")
        log_ok "$logfile existe (${SIZE}, ${LINES} líneas)"
    else
        log_warning "$logfile no existe: $LOG_PATH"
    fi
done

# 6. Verificar logrotate en cron
log_step "Verificando configuración de cron..."
if [[ -f /etc/cron.daily/logrotate ]]; then
    log_ok "logrotate está configurado en cron.daily"
    
    # Verificar si es ejecutable
    if [[ -x /etc/cron.daily/logrotate ]]; then
        log_ok "Script de cron es ejecutable"
    else
        log_warning "Script de cron no es ejecutable"
    fi
else
    log_warning "logrotate no está en cron.daily"
fi

# 7. Verificar estado de logrotate
log_step "Verificando estado de logrotate..."
if [[ -f /var/lib/logrotate/status ]]; then
    log_ok "Archivo de estado existe"
    
    # Buscar entradas de nuestros logs
    if grep -q "auto_fichaje" /var/lib/logrotate/status 2>/dev/null; then
        log_ok "Entradas encontradas en estado de logrotate"
        echo "  Estado actual:"
        grep "auto_fichaje" /var/lib/logrotate/status | while read -r line; do
            echo "    $line"
        done
    else
        log_info "No hay entradas aún (normal si es primera instalación)"
    fi
else
    log_warning "Archivo de estado de logrotate no existe"
fi

# 8. Verificar archivos rotados
log_step "Verificando archivos rotados existentes..."
ROTATED_COUNT=0
for logfile in "${LOG_FILES[@]}"; do
    PATTERN="$LOGS_DIR/${logfile}-*"
    ROTATED_FILES=($(ls $PATTERN 2>/dev/null || true))
    if [[ ${#ROTATED_FILES[@]} -gt 0 ]]; then
        log_ok "${logfile}: ${#ROTATED_FILES[@]} archivos rotados encontrados"
        ROTATED_COUNT=$((ROTATED_COUNT + ${#ROTATED_FILES[@]}))
    else
        log_info "${logfile}: no hay archivos rotados (normal si es nueva instalación)"
    fi
done

# 9. Verificar espacio en disco
log_step "Verificando espacio en disco..."
if [[ -d "$LOGS_DIR" ]]; then
    DISK_USAGE=$(du -sh "$LOGS_DIR" 2>/dev/null | cut -f1)
    AVAILABLE_SPACE=$(df -h "$LOGS_DIR" | awk 'NR==2 {print $4}')
    log_ok "Uso actual: $DISK_USAGE, Disponible: $AVAILABLE_SPACE"
else
    log_info "Directorio no existe, no se puede verificar espacio"
fi

# 10. Test de rotación (solo si se ejecuta como root)
if [[ $EUID -eq 0 ]]; then
    log_step "Ejecutando test de rotación..."
    if logrotate -f "$LOGROTATE_CONFIG" >/dev/null 2>&1; then
        log_ok "Test de rotación exitoso"
    else
        log_warning "Test de rotación falló (verificar logs)"
    fi
else
    log_info "Test de rotación omitido (requiere permisos de root)"
    echo "  Ejecutar como root para test completo: sudo bash $0"
fi

echo
echo "================================================="
echo "RESUMEN DE VERIFICACIÓN"
echo "================================================="

# Resumen de estado
ISSUES=0

echo "CONFIGURACIÓN:"
echo "  - Archivo de configuración: $([ -f "$LOGROTATE_CONFIG" ] && echo "✓" || echo "✗")"
echo "  - Directorio de logs: $([ -d "$LOGS_DIR" ] && echo "✓" || echo "✗")"
echo "  - Configuración en cron: $([ -f /etc/cron.daily/logrotate ] && echo "✓" || echo "✗")"

echo
echo "ARCHIVOS DE LOGS:"
for logfile in "${LOG_FILES[@]}"; do
    LOG_PATH="$LOGS_DIR/$logfile"
    echo "  - $logfile: $([ -f "$LOG_PATH" ] && echo "✓" || echo "✗")"
done

echo
echo "ESTADÍSTICAS:"
echo "  - Archivos rotados: $ROTATED_COUNT"
echo "  - Uso de disco: ${DISK_USAGE:-"N/A"}"

echo
echo "COMANDOS ÚTILES:"
echo "  - Verificar configuración: sudo logrotate -d $LOGROTATE_CONFIG"
echo "  - Forzar rotación: sudo logrotate -f $LOGROTATE_CONFIG"
echo "  - Ver estado: sudo cat /var/lib/logrotate/status | grep auto_fichaje"
echo "  - Ver logs de rotación: sudo tail -f /var/log/logrotate.log"

if [[ $ISSUES -eq 0 ]]; then
    echo
    log_ok "Verificación completada - No se encontraron problemas críticos"
else
    echo
    log_warning "Verificación completada - Se encontraron $ISSUES problemas"
fi

echo
