package com.fichajespi.dto;

import java.time.LocalTime;
import java.util.List;

public class HorarioUsuarioDTO {
    
    private Long id;
    private Long usuarioId;
    private String usuarioNombre;
    private Integer diaSemana;
    private String diaSemanaDescripcion;
    private Integer turnoNumero;
    private LocalTime horaInicio;
    private LocalTime horaFin;
    private Boolean activo;
    private String descripcion;
    private String timezone;
    
    // Constructores
    public HorarioUsuarioDTO() {}
    
    public HorarioUsuarioDTO(Long id, Long usuarioId, String usuarioNombre, Integer diaSemana, 
                           Integer turnoNumero, LocalTime horaInicio, LocalTime horaFin, 
                           Boolean activo, String descripcion) {
        this.id = id;
        this.usuarioId = usuarioId;
        this.usuarioNombre = usuarioNombre;
        this.diaSemana = diaSemana;
        this.turnoNumero = turnoNumero;
        this.horaInicio = horaInicio;
        this.horaFin = horaFin;
        this.activo = activo;
        this.descripcion = descripcion;
        this.timezone = "Europe/Madrid"; // Default
        this.diaSemanaDescripcion = getDiaSemanaNombre();
    }
    
    public HorarioUsuarioDTO(Long id, Long usuarioId, String usuarioNombre, Integer diaSemana, 
                           Integer turnoNumero, LocalTime horaInicio, LocalTime horaFin, 
                           Boolean activo, String descripcion, String timezone) {
        this.id = id;
        this.usuarioId = usuarioId;
        this.usuarioNombre = usuarioNombre;
        this.diaSemana = diaSemana;
        this.turnoNumero = turnoNumero;
        this.horaInicio = horaInicio;
        this.horaFin = horaFin;
        this.activo = activo;
        this.descripcion = descripcion;
        this.timezone = timezone != null ? timezone : "Europe/Madrid";
        this.diaSemanaDescripcion = getDiaSemanaNombre();
    }
    
    // Getters y Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Long getUsuarioId() {
        return usuarioId;
    }
    
    public void setUsuarioId(Long usuarioId) {
        this.usuarioId = usuarioId;
    }
    
    public String getUsuarioNombre() {
        return usuarioNombre;
    }
    
    public void setUsuarioNombre(String usuarioNombre) {
        this.usuarioNombre = usuarioNombre;
    }
    
    public Integer getDiaSemana() {
        return diaSemana;
    }
    
    public void setDiaSemana(Integer diaSemana) {
        this.diaSemana = diaSemana;
        this.diaSemanaDescripcion = getDiaSemanaNombre();
    }
    
    public String getDiaSemanaDescripcion() {
        return diaSemanaDescripcion;
    }
    
    public void setDiaSemanaDescripcion(String diaSemanaDescripcion) {
        this.diaSemanaDescripcion = diaSemanaDescripcion;
    }
    
    public Integer getTurnoNumero() {
        return turnoNumero;
    }
    
    public void setTurnoNumero(Integer turnoNumero) {
        this.turnoNumero = turnoNumero;
    }
    
    public LocalTime getHoraInicio() {
        return horaInicio;
    }
    
    public void setHoraInicio(LocalTime horaInicio) {
        this.horaInicio = horaInicio;
    }
    
    public LocalTime getHoraFin() {
        return horaFin;
    }
    
    public void setHoraFin(LocalTime horaFin) {
        this.horaFin = horaFin;
    }
    
    public Boolean getActivo() {
        return activo;
    }
    
    public void setActivo(Boolean activo) {
        this.activo = activo;
    }
    
    public String getDescripcion() {
        return descripcion;
    }
    
    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }
    
    public String getTimezone() {
        return timezone;
    }
    
    public void setTimezone(String timezone) {
        this.timezone = timezone != null ? timezone : "Europe/Madrid";
    }
    
    // Método utilitario
    private String getDiaSemanaNombre() {
        if (diaSemana == null) return "";
        switch (diaSemana) {
            case 1: return "Lunes";
            case 2: return "Martes";
            case 3: return "Miércoles";
            case 4: return "Jueves";
            case 5: return "Viernes";
            case 6: return "Sábado";
            case 7: return "Domingo";
            default: return "Desconocido";
        }
    }
    
    // DTO para crear/actualizar
    public static class CreateUpdateDTO {
        private Long usuarioId;
        private Integer diaSemana;
        private List<TurnoDTO> turnos;
        private String timezone;
        
        public static class TurnoDTO {
            private Integer turnoNumero;
            private LocalTime horaInicio;
            private LocalTime horaFin;
            private String descripcion;
            
            // Constructores
            public TurnoDTO() {}
            
            public TurnoDTO(Integer turnoNumero, LocalTime horaInicio, LocalTime horaFin, String descripcion) {
                this.turnoNumero = turnoNumero;
                this.horaInicio = horaInicio;
                this.horaFin = horaFin;
                this.descripcion = descripcion;
            }
            
            // Getters y Setters
            public Integer getTurnoNumero() {
                return turnoNumero;
            }
            
            public void setTurnoNumero(Integer turnoNumero) {
                this.turnoNumero = turnoNumero;
            }
            
            public LocalTime getHoraInicio() {
                return horaInicio;
            }
            
            public void setHoraInicio(LocalTime horaInicio) {
                this.horaInicio = horaInicio;
            }
            
            public LocalTime getHoraFin() {
                return horaFin;
            }
            
            public void setHoraFin(LocalTime horaFin) {
                this.horaFin = horaFin;
            }
            
            public String getDescripcion() {
                return descripcion;
            }
            
            public void setDescripcion(String descripcion) {
                this.descripcion = descripcion;
            }
        }
        
        // Getters y Setters de CreateUpdateDTO
        public Long getUsuarioId() {
            return usuarioId;
        }
        
        public void setUsuarioId(Long usuarioId) {
            this.usuarioId = usuarioId;
        }
        
        public Integer getDiaSemana() {
            return diaSemana;
        }
        
        public void setDiaSemana(Integer diaSemana) {
            this.diaSemana = diaSemana;
        }
        
        public List<TurnoDTO> getTurnos() {
            return turnos;
        }
        
        public void setTurnos(List<TurnoDTO> turnos) {
            this.turnos = turnos;
        }
        
        public String getTimezone() {
            return timezone;
        }
        
        public void setTimezone(String timezone) {
            this.timezone = timezone;
        }
    }
}
