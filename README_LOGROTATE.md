# CONFIGURACIÓN DE LOGROTATE PARA FICHAJES AUTOMÁTICOS

## Descripción

Este documento explica cómo configurar logrotate en Debian 12 para gestionar automáticamente los archivos de logs generados por los scripts de fichaje automático.

## ¿Qué es logrotate?

Logrotate es una herramienta del sistema que automatiza la rotación, compresión y eliminación de archivos de log. Esto previene que los logs crezcan indefinidamente y consuman todo el espacio en disco.

## Archivos de configuración

### 1. `logrotate-auto-fichaje.conf`
Archivo de configuración principal con todas las opciones documentadas.

### 2. `install-logrotate.sh`
Script de instalación automática que configura logrotate en el sistema.

## Instalación rápida

```bash
# 1. Copiar los archivos al servidor Debian 12
scp logrotate-auto-fichaje.conf install-logrotate.sh usuario@servidor:/tmp/

# 2. Conectar al servidor y ejecutar la instalación
ssh usuario@servidor
sudo bash /tmp/install-logrotate.sh
```

## Instalación manual

### Paso 1: Verificar que logrotate está instalado

```bash
# Verificar instalación
which logrotate

# Si no está instalado
sudo apt update
sudo apt install logrotate
```

### Paso 2: Crear directorio de logs

```bash
sudo mkdir -p /opt/fichajes/scripts/logs
sudo chmod 755 /opt/fichajes/scripts/logs
```

### Paso 3: Crear configuración de logrotate

```bash
sudo nano /etc/logrotate.d/auto-fichaje
```

Contenido del archivo:

```bash
# Configuración para logs de fichajes automáticos
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
```

### Paso 4: Establecer permisos

```bash
sudo chmod 644 /etc/logrotate.d/auto-fichaje
```

## Configuración explicada

### Opciones principales

- **`daily`**: Rotación diaria de logs
- **`rotate 30`**: Mantener 30 archivos rotados (30 días de historial)
- **`compress`**: Comprimir archivos rotados para ahorrar espacio
- **`delaycompress`**: No comprimir el último archivo rotado
- **`missingok`**: No fallar si el archivo de log no existe
- **`notifempty`**: No rotar archivos vacíos
- **`create 0644 root root`**: Crear nuevo archivo con permisos específicos
- **`dateext`**: Usar fechas en nombres de archivos rotados
- **`dateformat -%Y%m%d`**: Formato de fecha YYYYMMDD

### Scripts de pre y post rotación

- **`prerotate`**: Se ejecuta antes de la rotación
  - Crea directorio de logs si no existe
  - Establece permisos correctos
  - Registra inicio de rotación

- **`postrotate`**: Se ejecuta después de la rotación
  - Recarga rsyslog si está disponible
  - Registra finalización de rotación

## Verificación y testing

### Verificar sintaxis de configuración

```bash
sudo logrotate -d /etc/logrotate.d/auto-fichaje
```

### Forzar rotación de prueba

```bash
sudo logrotate -f /etc/logrotate.d/auto-fichaje
```

### Ver estado de logrotate

```bash
sudo cat /var/lib/logrotate/status | grep auto_fichaje
```

### Verificar logs de logrotate

```bash
sudo tail -f /var/log/logrotate.log
```

## Resultado esperado

Después de la configuración:

```
/opt/fichajes/scripts/logs/
├── auto_fichaje.log                    # Log actual
├── auto_fichaje.log-20250731           # Log rotado de ayer
├── auto_fichaje.log-20250730.gz        # Log comprimido
├── auto_fichaje_entrada.log            # Log actual de entradas
├── auto_fichaje_entrada.log-20250731   # Log rotado
└── auto_fichaje_salida.log             # Log actual de salidas
```

## Monitorización

### Verificar que la rotación funciona

```bash
# Ver archivos en directorio de logs
ls -la /opt/fichajes/scripts/logs/

# Verificar última ejecución de logrotate
grep "auto_fichaje" /var/lib/logrotate/status

# Ver logs de rotación
tail -n 20 /var/log/logrotate.log
```

### Comando para verificar tamaño de logs

```bash
du -h /opt/fichajes/scripts/logs/
```

## Configuraciones alternativas

### Rotación por tamaño en lugar de tiempo

```bash
/opt/fichajes/scripts/logs/*.log {
    size 10M
    rotate 5
    compress
    missingok
    notifempty
    create 0644 root root
}
```

### Rotación semanal con más retención

```bash
/opt/fichajes/scripts/logs/*.log {
    weekly
    rotate 12    # 3 meses de historial
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
    dateext
}
```

## Troubleshooting

### Problemas comunes

1. **Error de permisos**
   ```bash
   sudo chown root:root /etc/logrotate.d/auto-fichaje
   sudo chmod 644 /etc/logrotate.d/auto-fichaje
   ```

2. **Directorio de logs no existe**
   ```bash
   sudo mkdir -p /opt/fichajes/scripts/logs
   sudo chmod 755 /opt/fichajes/scripts/logs
   ```

3. **Logrotate no se ejecuta**
   ```bash
   # Verificar que está en cron
   ls -la /etc/cron.daily/logrotate
   
   # Verificar logs del sistema
   sudo journalctl -u cron | grep logrotate
   ```

4. **Configuración con errores**
   ```bash
   # Verificar sintaxis
   sudo logrotate -d /etc/logrotate.d/auto-fichaje
   ```

## Integración con scripts de fichaje

Para que los scripts utilicen la ruta correcta de logs, actualizar `scripts-config.properties`:

```properties
# Archivo de logs (ruta absoluta para logrotate)
LOG_FILE=/opt/fichajes/scripts/logs/auto_fichaje.log
```

## Mantenimiento

### Tareas regulares

1. **Verificar funcionamiento mensual**
   ```bash
   sudo logrotate -d /etc/logrotate.d/auto-fichaje
   ```

2. **Limpiar logs muy antiguos (si es necesario)**
   ```bash
   find /opt/fichajes/scripts/logs/ -name "*.gz" -mtime +60 -delete
   ```

3. **Monitorizar espacio en disco**
   ```bash
   df -h /opt/fichajes/scripts/logs/
   ```

## Seguridad

- Los archivos de configuración son propiedad de root
- Los logs rotados mantienen permisos restrictivos (644)
- Solo root puede modificar la configuración de logrotate
- Los logs históricos se comprimen automáticamente

## Referencias

- [Manual de logrotate](https://linux.die.net/man/8/logrotate)
- [Configuración avanzada de logrotate](https://www.thegeekdiary.com/understanding-logrotate-utility/)
- [Debian logrotate documentation](https://wiki.debian.org/logrotate)
