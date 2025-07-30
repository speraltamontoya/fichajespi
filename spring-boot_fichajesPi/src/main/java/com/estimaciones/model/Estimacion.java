package com.estimaciones.model;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "estimaciones")
public class Estimacion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "usuario_id", nullable = false)
    private String usuarioId;  // Referencia al campo 'numero' de usuarios, no al 'id'

    @Column(name = "horas_estimadas", nullable = false)
    private Double horasEstimadas;

    @Column(name = "fecha", nullable = false)
    private LocalDateTime fecha;

    // Getters y setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUsuarioId() { return usuarioId; }
    public void setUsuarioId(String usuarioId) { this.usuarioId = usuarioId; }

    public Double getHorasEstimadas() { return horasEstimadas; }
    public void setHorasEstimadas(Double horasEstimadas) { this.horasEstimadas = horasEstimadas; }

    public LocalDateTime getFecha() { return fecha; }
    public void setFecha(LocalDateTime fecha) { this.fecha = fecha; }
}
