-- Tabla para gestionar horarios de usuarios por día de la semana
CREATE TABLE IF NOT EXISTS horarios_usuario (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    dia_semana INT NOT NULL COMMENT '1=Lunes, 2=Martes, 3=Miércoles, 4=Jueves, 5=Viernes, 6=Sábado, 7=Domingo',
    turno_numero INT NOT NULL COMMENT 'Número del turno en el día (1, 2, 3...)',
    hora_inicio TIME NOT NULL COMMENT 'Hora de inicio del turno',
    hora_fin TIME NOT NULL COMMENT 'Hora de fin del turno',
    activo BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Si el horario está activo',
    descripcion VARCHAR(255) COMMENT 'Descripción opcional del turno',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Índices
    INDEX idx_usuario_dia (usuario_id, dia_semana),
    INDEX idx_dia_semana (dia_semana),
    INDEX idx_activo (activo)
);

-- Insertar algunos horarios de ejemplo
INSERT INTO horarios_usuario (usuario_id, dia_semana, turno_numero, hora_inicio, hora_fin, descripcion) VALUES
-- Usuario AdminFichajesPi (ID 1) - Horario partido de lunes a viernes
(1, 1, 1, '08:00:00', '12:00:00', 'Mañana'),
(1, 1, 2, '20:00:00', '24:00:00', 'Noche'),
(1, 2, 1, '08:00:00', '12:00:00', 'Mañana'),
(1, 2, 2, '20:00:00', '24:00:00', 'Noche'),
(1, 3, 1, '08:00:00', '12:00:00', 'Mañana'),
(1, 3, 2, '20:00:00', '24:00:00', 'Noche'),
(1, 4, 1, '08:00:00', '12:00:00', 'Mañana'),
(1, 4, 2, '20:00:00', '24:00:00', 'Noche'),
(1, 5, 1, '08:00:00', '12:00:00', 'Mañana'),
(1, 5, 2, '20:00:00', '24:00:00', 'Noche');

-- Si existe el usuario Santiago (buscar por número)
INSERT INTO horarios_usuario (usuario_id, dia_semana, turno_numero, hora_inicio, hora_fin, descripcion) 
SELECT u.id, 1, 1, '13:00:00', '17:00:00', 'Tarde' FROM usuarios u WHERE u.numero = '4086855489'
UNION ALL
SELECT u.id, 2, 1, '13:00:00', '17:00:00', 'Tarde' FROM usuarios u WHERE u.numero = '4086855489'
UNION ALL
SELECT u.id, 3, 1, '13:00:00', '17:00:00', 'Tarde' FROM usuarios u WHERE u.numero = '4086855489'
UNION ALL
SELECT u.id, 4, 1, '13:00:00', '17:00:00', 'Tarde' FROM usuarios u WHERE u.numero = '4086855489'
UNION ALL
SELECT u.id, 5, 1, '13:00:00', '17:00:00', 'Tarde' FROM usuarios u WHERE u.numero = '4086855489';
