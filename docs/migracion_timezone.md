# Migración de Arquitectura de Timezone

## Problema actual
- Datos se almacenan en UTC pero en campos separados (dia VARCHAR, hora VARCHAR)
- Frontend recibe strings sin información de timezone
- Conversiones inconsistentes e impredecibles

## Solución recomendada: Migración a TIMESTAMP

### 1. Cambios en Base de Datos

#### Opción A: Campo unificado (recomendado)
```sql
-- Agregar nuevo campo timestamp
ALTER TABLE fichajes ADD COLUMN fecha_hora_utc TIMESTAMP;

-- Migrar datos existentes combinando dia + hora como UTC
UPDATE fichajes 
SET fecha_hora_utc = (dia || ' ' || hora || ':00')::timestamp AT TIME ZONE 'UTC';

-- Verificar migración
SELECT dia, hora, fecha_hora_utc, 
       fecha_hora_utc AT TIME ZONE 'Europe/Madrid' as hora_local_madrid
FROM fichajes LIMIT 5;

-- Una vez verificado, deprecar campos antiguos
-- ALTER TABLE fichajes DROP COLUMN dia, DROP COLUMN hora;
```

#### Opción B: Campos separados con timezone (alternativa)
```sql
-- Convertir campos existentes a timestamp
ALTER TABLE fichajes ALTER COLUMN dia TYPE DATE USING dia::date;
ALTER TABLE fichajes ALTER COLUMN hora TYPE TIME USING hora::time;
ADD COLUMN timezone VARCHAR(50) DEFAULT 'UTC';
```

### 2. Cambios en Backend (Spring Boot)

#### Entidad actualizada
```java
@Entity
@Table(name = "fichajes")
public class Fichaje {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    // Nuevo campo principal
    @Column(name = "fecha_hora_utc")
    private Instant fechaHoraUtc;
    
    // Campos legacy (deprecados)
    @Deprecated
    @Column(name = "dia")
    private String dia;
    
    @Deprecated
    @Column(name = "hora") 
    private String hora;
    
    // Getters que convierten automáticamente
    public LocalDate getDiaLocal() {
        return fechaHoraUtc.atZone(ZoneId.of("Europe/Madrid")).toLocalDate();
    }
    
    public LocalTime getHoraLocal() {
        return fechaHoraUtc.atZone(ZoneId.of("Europe/Madrid")).toLocalTime();
    }
    
    public String getDiaFormateado() {
        return getDiaLocal().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    }
    
    public String getHoraFormateada() {
        return getHoraLocal().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
    }
}
```

#### DTO con conversión automática
```java
public class FichajeDTO {
    private Long id;
    private Instant fechaHoraUtc;
    private String tipo;
    
    // Campos calculados para frontend
    private String dia;           // Formato dd/MM/yyyy en timezone local
    private String hora;          // Formato HH:mm:ss en timezone local
    private String diaISO;        // Formato yyyy-MM-dd para inputs
    private String horaISO;       // Formato HH:mm para inputs
    
    // Constructor desde entidad
    public static FichajeDTO fromEntity(Fichaje fichaje, ZoneId targetZone) {
        ZonedDateTime localTime = fichaje.getFechaHoraUtc().atZone(targetZone);
        
        return FichajeDTO.builder()
            .id(fichaje.getId())
            .fechaHoraUtc(fichaje.getFechaHoraUtc())
            .tipo(fichaje.getTipo())
            .dia(localTime.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")))
            .hora(localTime.format(DateTimeFormatter.ofPattern("HH:mm:ss")))
            .diaISO(localTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd")))
            .horaISO(localTime.format(DateTimeFormatter.ofPattern("HH:mm")))
            .build();
    }
}
```

### 3. Cambios en Frontend (Angular)

#### Eliminar conversiones manuales
```typescript
// El servicio recibe datos ya convertidos del backend
@Injectable()
export class FichajeService {
    
    listarFichajes(dto: FichajeFilterDto): Observable<PageResponse<FichajeDto>> {
        // El backend ya envía fechas convertidas a la zona horaria solicitada
        const params = { 
            ...dto, 
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone 
        };
        
        return this.http.post<PageResponse<FichajeDto>>(`${this.baseUrl}/listFiltered`, params);
        // NO necesita conversión manual - el backend hace todo
    }
}
```

#### Template simplificado
```html
<tr *ngFor="let elemento of listaElementos">
    <!-- Datos ya vienen formateados desde backend -->
    <td>{{elemento.dia}}</td>          <!-- dd/MM/yyyy -->
    <td>{{elemento.hora}}</td>         <!-- HH:mm:ss -->
    <td>{{elemento.tipo}}</td>
</tr>
```

### 4. Migración gradual

#### Fase 1: Compatibilidad dual
- Agregar campo `fecha_hora_utc`
- Mantener campos `dia` y `hora` existentes
- Backend popula ambos sistemas
- Frontend sigue usando campos antiguos

#### Fase 2: Migración backend
- Backend usa nuevo campo para lógica interna
- Convertir APIs una por una
- Mantener compatibilidad con frontend

#### Fase 3: Migración frontend
- Frontend migra a nuevos campos
- Eliminar lógica de conversión manual
- Usar datos pre-convertidos del backend

#### Fase 4: Limpieza
- Eliminar campos `dia` y `hora` antiguos
- Limpiar código legacy

### 5. Ventajas de esta arquitectura

✅ **Consistencia**: Datos siempre en UTC en base de datos
✅ **Escalabilidad**: Soporte nativo para múltiples timezones
✅ **Simplicidad**: Frontend sin lógica de conversión
✅ **Precisión**: Timestamps exactos con información de timezone
✅ **Estándares**: Uso de tipos nativos de fecha/hora
✅ **Mantenibilidad**: Lógica centralizada en backend

### 6. Script de migración completo

```sql
-- 1. Backup de seguridad
CREATE TABLE fichajes_backup AS SELECT * FROM fichajes;

-- 2. Agregar nueva columna
ALTER TABLE fichajes ADD COLUMN fecha_hora_utc TIMESTAMP;

-- 3. Migrar datos existentes
UPDATE fichajes 
SET fecha_hora_utc = (
    CASE 
        WHEN hora LIKE '%:%' THEN 
            (dia || ' ' || hora || ':00')::timestamp AT TIME ZONE 'UTC'
        ELSE 
            (dia || ' ' || hora || ':00:00')::timestamp AT TIME ZONE 'UTC'
    END
)
WHERE fecha_hora_utc IS NULL;

-- 4. Verificar migración
SELECT COUNT(*) as total_registros,
       COUNT(fecha_hora_utc) as migrados,
       COUNT(*) - COUNT(fecha_hora_utc) as pendientes
FROM fichajes;

-- 5. Crear índice para performance
CREATE INDEX idx_fichajes_fecha_hora_utc ON fichajes(fecha_hora_utc);

-- 6. Verificar conversiones de ejemplo
SELECT dia, hora, 
       fecha_hora_utc as utc_timestamp,
       fecha_hora_utc AT TIME ZONE 'Europe/Madrid' as madrid_time
FROM fichajes 
ORDER BY fecha_hora_utc DESC 
LIMIT 10;
```

## Conclusión

Esta migración resuelve el problema de raíz y prepara la aplicación para:
- Soporte multizona horaria
- Precisión en fechas/horas
- Simplicidad en el frontend
- Escalabilidad futura
