package com.fichajespi.entity;

import javax.persistence.*;
import java.time.LocalTime;

@Entity
@Table(name = "horarios_usuario")
public class HorarioUsuario {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;
    
    @Column(name = "dia_semana", nullable = false)
    private Integer diaSemana; // 1=Lunes, 2=Martes, ..., 7=Domingo
    
    @Column(name = "turno_numero", nullable = false)
    private Integer turnoNumero; // 1, 2, 3... para múltiples turnos en el día
    
    @Column(name = "hora_inicio", nullable = false)
    private LocalTime horaInicio;
    
    @Column(name = "hora_fin", nullable = false)
    private LocalTime horaFin;
    
    @Column(name = "activo", nullable = false)
    private Boolean activo = true;
    
    @Column(name = "descripcion")
    private String descripcion;
    
    @Column(name = "timezone", length = 50)
    private String timezone = "Europe/Madrid";  // Zona horaria por defecto
    
    // Constructores
    public HorarioUsuario() {}
    
    public HorarioUsuario(Usuario usuario, Integer diaSemana, Integer turnoNumero, 
                         LocalTime horaInicio, LocalTime horaFin, String descripcion) {
        this.usuario = usuario;
        this.diaSemana = diaSemana;
        this.turnoNumero = turnoNumero;
        this.horaInicio = horaInicio;
        this.horaFin = horaFin;
        this.descripcion = descripcion;
        this.activo = true;
        this.timezone = "Europe/Madrid";  // Default
    }
    
    public HorarioUsuario(Usuario usuario, Integer diaSemana, Integer turnoNumero, 
                         LocalTime horaInicio, LocalTime horaFin, String descripcion, String timezone) {
        this.usuario = usuario;
        this.diaSemana = diaSemana;
        this.turnoNumero = turnoNumero;
        this.horaInicio = horaInicio;
        this.horaFin = horaFin;
        this.descripcion = descripcion;
        this.activo = true;
        this.timezone = timezone != null ? timezone : "Europe/Madrid";
    }
    
    // Getters y Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Usuario getUsuario() {
        return usuario;
    }
    
    public void setUsuario(Usuario usuario) {
        this.usuario = usuario;
    }
    
    public Integer getDiaSemana() {
        return diaSemana;
    }
    
    public void setDiaSemana(Integer diaSemana) {
        this.diaSemana = diaSemana;
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
    
    // Métodos utilitarios
    public String getDiaSemanaNombre() {
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
    
    @Override
    public String toString() {
        return "HorarioUsuario{" +
                "id=" + id +
                ", diaSemana=" + diaSemana +
                ", turnoNumero=" + turnoNumero +
                ", horaInicio=" + horaInicio +
                ", horaFin=" + horaFin +
                ", activo=" + activo +
                ", descripcion='" + descripcion + '\'' +
                ", timezone='" + timezone + '\'' +
                '}';
    }
}
