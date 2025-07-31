# Script de Fichaje Automático de Salida

Este script automatiza el registro de salidas basándose en las estimaciones de tiempo de trabajo de los empleados. **El sistema completo trabaja en UTC** para máxima precisión y compatibilidad internacional.

## Funcionalidad

- Se ejecuta cada 5 minutos (configurado vía cron)
- Revisa empleados que han fichado entrada y están trabajando  
- Busca estimaciones de tiempo asociadas al fichaje de entrada
- Si no hay estimación, usa 4 horas por defecto
- Registra salida automática cuando ha pasado: **tiempo de estimación + 1 hora de tolerancia**
- La salida se registra con un tiempo aleatorio de 0-5 minutos adicionales
- **Todos los cálculos se realizan en UTC para máxima precisión**

## Arquitectura UTC Global

### Beneficios del Sistema UTC:
- **Precisión internacional**: Funciona en cualquier país/zona horaria
- **Cálculos exactos**: Sin errores por cambios de horario de verano/invierno
- **Consistencia**: Todos los componentes usan la misma referencia temporal
- **Escalabilidad**: Compatible con equipos distribuidos globalmente

### Solución Implementada:

#### 1. Frontend (Angular):
- Modificado para enviar fechas en horario local como LocalDateTime
- Formato: `YYYY-MM-DDTHH:mm:ss` (sin Z de UTC)
- Consistente con la zona horaria del backend

#### 2. Backend (Spring Boot):
- Configurado `TimeZone.setDefault("Europe/Madrid")` en Application.java
- Agregado `@JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")` en entidad Estimacion
- Toda la aplicación trabaja en Europe/Madrid

#### 3. Script de Bash:
- Búsqueda ampliada de ±30 minutos para encontrar estimaciones
- Limpieza de datos numéricos robusta
- Manejo de errores mejorado

## Configuración

### 1. Permisos de ejecución
```bash
chmod +x auto_fichaje_salida.sh
```

### 2. Configuración de base de datos
El script está configurado para usar las credenciales del docker-compose.yml:
- Host: localhost
- Puerto: 3306
- Base de datos: db_fichajespi
- Usuario: fichajes
- Contraseña: fichajesP0l1

### 3. Dependencias
Asegúrate de tener instalados:
```bash
sudo apt-get update
sudo apt-get install mysql-client bc
```

### 4. Configuración de cron
Para ejecutar el script cada 5 minutos, agrega esta línea al crontab:
```bash
crontab -e
```

Agregar:
```
*/5 * * * * /ruta/completa/al/script/auto_fichaje_salida.sh
```

## Scripts de Prueba

### Verificar funcionamiento:
```bash
chmod +x test_script.sh
./test_script.sh
```

Este script de prueba verifica:
- Conexión a la base de datos
- Usuarios con entradas activas  
- Estimaciones registradas
- Funcionamiento de cálculos matemáticos

## Parámetros configurables

En el script puedes modificar:

- `DEFAULT_ESTIMATION_HOURS=4.0` - Estimación por defecto si no hay registro
- `TOLERANCE_HOURS=1.0` - Horas adicionales antes de registrar salida automática
- Configuración de base de datos si difiere del docker-compose

## Funcionamiento detallado

1. **Búsqueda de candidatos**: Encuentra usuarios con `working = 1` y último fichaje de tipo "ENTRADA"

2. **Búsqueda de estimación**: 
   - Busca en tabla `estimaciones` una entrada para el usuario
   - **Nueva implementación**: Búsqueda en ventana de ±30 minutos
   - Todas las fechas ahora en horario local (Europe/Madrid)
   - Si no encuentra estimación, usa 4 horas por defecto

3. **Cálculo de salida**:
   - Tiempo de salida = Hora entrada + Estimación + 1 hora tolerancia + Random(0-5 min)

4. **Verificaciones**:
   - Verifica que no exista ya un fichaje de salida posterior
   - Solo registra si ha pasado el tiempo calculado

5. **Registro**:
   - Inserta nuevo fichaje con origen "auto"
   - Actualiza `ultimo_fichaje` del usuario
   - Cambia `working` a 0

## Logs

El script genera logs en `auto_fichaje.log` con información detallada de:
- Procesamiento de cada usuario
- Estimaciones encontradas
- Salidas registradas
- Errores

## Tabla de estimaciones

El script espera que exista una tabla `estimaciones` con la estructura:
```sql
CREATE TABLE estimaciones (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id VARCHAR(255) NOT NULL,  -- Referencia al campo 'numero' de la tabla usuarios
    horas_estimadas DOUBLE NOT NULL,
    fecha DATETIME NOT NULL
);
```

**Importante**: El campo `usuario_id` en la tabla `estimaciones` hace referencia al campo `numero` de la tabla `usuarios`, no al `id`.

### Cambios aplicados para consistencia:
- **Backend**: Entidad `Estimacion` usa `String usuarioId` 
- **Frontend**: DTO usa `string usuarioId` y envía `model.numero`
- **App escritorio**: `EstimacionHoras` usa `String usuarioId`
- **Script**: Busca por `usuario_numero` en lugar de `user_id`

Esta tabla se crea automáticamente desde el frontend cuando un usuario ficha entrada y proporciona una estimación.

## Gestión de Zonas Horarias

El script maneja automáticamente las diferencias de zona horaria entre las diferentes aplicaciones:

- **App de escritorio**: Guarda estimaciones en horario local (Europe/Madrid)
- **Frontend web**: Guarda estimaciones en UTC debido a `new Date().toISOString()`

El script busca estimaciones en ambas zonas horarias para asegurar compatibilidad:
```sql
-- Busca en horario local (Madrid) para app escritorio
fecha BETWEEN DATE_SUB('entrada_local', INTERVAL 5 MINUTE) AND DATE_ADD('entrada_local', INTERVAL 5 MINUTE)
-- Y también en horario UTC para frontend
fecha BETWEEN DATE_SUB('entrada_utc', INTERVAL 5 MINUTE) AND DATE_ADD('entrada_utc', INTERVAL 5 MINUTE)
```

Esto resuelve el problema de desfase de 2 horas entre frontend y app de escritorio.

## Seguridad

- El script no modifica estimaciones existentes
- Solo registra salidas, nunca elimina fichajes
- Verifica conexión a BD antes de ejecutar
- Logs detallados para auditoría
