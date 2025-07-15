package com.fichajespi.fichajespidestopapp.httpClient;

import com.fichajespi.fichajespidestopapp.entity.EstimacionHoras;
import feign.Headers;
import feign.RequestLine;

@Headers({"Content-Type: application/json"})
public interface EstimacionFeignController {
    @RequestLine("POST /api/estimaciones")
    void crearEstimacion(EstimacionHoras estimacion);
}
