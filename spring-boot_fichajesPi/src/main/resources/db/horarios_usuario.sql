-- Script para crear la tabla horarios_usuario
-- Base de datos: fichajespi

USE fichajespi;

-- Crear tabla horarios_usuario
CREATE TABLE IF NOT EXISTS horarios_usuario (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    dia_semana INT NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
    turno_numero INT NOT NULL CHECK (turno_numero >= 1),
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    descripcion VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Índices para mejorar el rendimiento
    INDEX idx_usuario_dia (usuario_id, dia_semana),
    INDEX idx_usuario_dia_turno (usuario_id, dia_semana, turno_numero),
    
    -- Constraint para evitar horarios solapados para el mismo usuario, día y turno
    UNIQUE KEY uk_usuario_dia_turno (usuario_id, dia_semana, turno_numero),
    
    -- Constraint para validar que hora_fin > hora_inicio
    CHECK (hora_fin > hora_inicio)
);

-- Insertar algunos datos de ejemplo (opcional)
-- Usuario 1 - Horario normal de oficina
INSERT INTO horarios_usuario (usuario_id, dia_semana, turno_numero, hora_inicio, hora_fin, descripcion) VALUES
(1, 1, 1, '09:00:00', '17:00:00', 'Jornada completa'),
(1, 2, 1, '09:00:00', '17:00:00', 'Jornada completa'),
(1, 3, 1, '09:00:00', '17:00:00', 'Jornada completa'),
(1, 4, 1, '09:00:00', '17:00:00', 'Jornada completa'),
(1, 5, 1, '09:00:00', '17:00:00', 'Jornada completa');

-- Usuario 2 - Horario partido (mañana y tarde)
INSERT INTO horarios_usuario (usuario_id, dia_semana, turno_numero, hora_inicio, hora_fin, descripcion) VALUES
(2, 1, 1, '08:00:00', '14:00:00', 'Turno mañana'),
(2, 1, 2, '16:00:00', '20:00:00', 'Turno tarde'),
(2, 2, 1, '08:00:00', '14:00:00', 'Turno mañana'),
(2, 2, 2, '16:00:00', '20:00:00', 'Turno tarde'),
(2, 3, 1, '08:00:00', '14:00:00', 'Turno mañana'),
(2, 3, 2, '16:00:00', '20:00:00', 'Turno tarde'),
(2, 4, 1, '08:00:00', '14:00:00', 'Turno mañana'),
(2, 4, 2, '16:00:00', '20:00:00', 'Turno tarde'),
(2, 5, 1, '08:00:00', '14:00:00', 'Turno mañana'),
(2, 5, 2, '16:00:00', '20:00:00', 'Turno tarde');

-- Usuario 3 - Horario de fin de semana
INSERT INTO horarios_usuario (usuario_id, dia_semana, turno_numero, hora_inicio, hora_fin, descripcion) VALUES
(3, 6, 1, '10:00:00', '18:00:00', 'Sábado'),
(3, 7, 1, '10:00:00', '18:00:00', 'Domingo');

-- Verificar los datos insertados
SELECT * FROM horarios_usuario ORDER BY usuario_id, dia_semana, turno_numero;
