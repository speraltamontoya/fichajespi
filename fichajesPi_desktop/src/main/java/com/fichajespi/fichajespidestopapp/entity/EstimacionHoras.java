package com.fichajespi.fichajespidestopapp.entity;

import java.time.LocalDateTime;

public class EstimacionHoras {
    private Long usuarioId;
    private Double horasEstimadas;
    private LocalDateTime fecha;

    public EstimacionHoras() {}

    public EstimacionHoras(Long usuarioId, Double horasEstimadas, LocalDateTime fecha) {
        this.usuarioId = usuarioId;
        this.horasEstimadas = horasEstimadas;
        this.fecha = fecha;
    }

    public Long getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(Long usuarioId) {
        this.usuarioId = usuarioId;
    }

    public Double getHorasEstimadas() {
        return horasEstimadas;
    }

    public void setHorasEstimadas(Double horasEstimadas) {
        this.horasEstimadas = horasEstimadas;
    }

    public LocalDateTime getFecha() {
        return fecha;
    }

    public void setFecha(LocalDateTime fecha) {
        this.fecha = fecha;
    }
}
