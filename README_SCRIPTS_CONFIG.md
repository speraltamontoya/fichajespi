# Configuración de Scripts de Automatización

## Descripción

Los scripts de automatización de fichajes han sido actualizados para usar un sistema de configuración centralizada. Esto mejora la seguridad al separar los datos sensibles del código fuente.

## Configuración Inicial

### 1. Crear archivo de configuración

Copie el archivo de ejemplo y ajuste la configuración:

```bash
cp example-scripts-config.properties scripts-config.properties
```

### 2. Editar configuración

Abra `scripts-config.properties` y configure:

```properties
# Base de datos
DB_HOST=localhost
DB_PORT=3306
DB_NAME=db_fichajespi
DB_USER=fichajes
DB_PASSWORD=tu_password_real

# Logging
LOG_LEVEL=INFO
LOG_FILE=./auto_fichaje.log

# Zona horaria
DEFAULT_TIMEZONE=Europe/Madrid

# Configuraciones específicas de fichajes
VENTANA_DETECCION=15
DEFAULT_ESTIMATION_HOURS=4.0
TOLERANCE_HOURS=1.0
```

## Scripts Disponibles

### Scripts de Fichaje Automático

- **`auto_fichaje_entrada.sh`**: Genera fichajes de entrada basados en horarios programados
- **`auto_fichaje_salida.sh`**: Genera fichajes de salida basados en estimaciones de tiempo
- **`simulador_fichajes_completos.sh`**: Simula fichajes completos para días perdidos

### Scripts de Prueba

- **`auto_fichaje_entrada_test.sh`**: Versión de prueba del script de entrada
- **`test_script.sh`**: Script de prueba de conectividad

## Funciones Comunes

El archivo `scripts-common.sh` proporciona funciones reutilizables:

- `load_config()`: Carga la configuración desde el archivo properties
- `validate_db_config()`: Valida la configuración de base de datos
- `test_db_connection()`: Prueba la conectividad con la base de datos
- `setup_logging()`: Configura el sistema de logging
- `log_message()`: Función centralizada para logs

## Archivos

```
├── example-scripts-config.properties  # Plantilla de configuración (se versiona)
├── scripts-config.properties         # Configuración real (no se versiona)
├── scripts-common.sh                 # Funciones comunes (se versiona)
├── auto_fichaje_entrada.sh           # Script principal de entrada
├── auto_fichaje_salida.sh            # Script principal de salida
├── simulador_fichajes_completos.sh   # Simulador de fichajes
├── auto_fichaje_entrada_test.sh      # Script de prueba
├── test_script.sh                    # Pruebas de conectividad
└── README_SCRIPTS_CONFIG.md          # Esta documentación
```

## Seguridad

- El archivo `scripts-config.properties` está excluido del control de versiones
- Solo se versiona el archivo `example-scripts-config.properties` como plantilla
- Todos los datos sensibles están centralizados en el archivo de configuración
- Las funciones comunes están disponibles para todos los scripts

## Configuración de Tolerancia

El script `auto_fichaje_salida.sh` utiliza el parámetro `TOLERANCE_HOURS` para determinar cuánto tiempo extra esperar antes de registrar la salida automática.

### Ejemplos de configuración:

```properties
# 30 minutos de tolerancia
TOLERANCE_HOURS=0.5

# 1 hora de tolerancia (valor por defecto)
TOLERANCE_HOURS=1.0

# 1 hora y 30 minutos de tolerancia
TOLERANCE_HOURS=1.5

# 15 minutos de tolerancia
TOLERANCE_HOURS=0.25
```

### Cómo funciona:

- Si un empleado tiene una estimación de 4 horas y TOLERANCE_HOURS=0.5
- El fichaje de salida se ejecutará 4.5 horas después de la entrada
- Pero la hora real de salida registrada será solo 4 horas + tiempo aleatorio (0-5 min)

## Instalación en Producción

1. Clone el repositorio
2. Copie el archivo de ejemplo: `cp example-scripts-config.properties scripts-config.properties`
3. Configure los valores reales en `scripts-config.properties`
4. Verifique la conectividad: `./test_script.sh`
5. Configure los cron jobs para los scripts de automatización

## Troubleshooting

### Error de configuración

Si aparece "ERROR: No se pudo cargar la configuración":
- Verifique que existe `scripts-config.properties`
- Compruebe que tiene los permisos de lectura
- Valide la sintaxis del archivo properties

### Error de conexión a base de datos

Si aparece "ERROR: Configuración de base de datos inválida":
- Verifique los parámetros de conexión en `scripts-config.properties`
- Pruebe la conectividad con `./test_script.sh`
- Compruebe que el servidor MySQL está ejecutándose

## Logs

Los logs se escriben en el archivo especificado en `LOG_FILE`. El formato incluye:
- Timestamp en UTC
- Nivel de log (INFO, DEBUG, ERROR, WARNING, SUCCESS)
- Mensaje descriptivo

Ejemplo:
```
[2025-01-31 10:30:45 UTC] [INFO] Iniciando script de fichaje automático basado en horarios-usuarios
[2025-01-31 10:30:45 UTC] [DEBUG] Configuración cargada: DB_HOST=localhost, DB_PORT=3306
```
