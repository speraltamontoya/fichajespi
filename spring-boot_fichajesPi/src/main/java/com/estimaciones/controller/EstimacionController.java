package com.estimaciones.controller;

import com.estimaciones.model.Estimacion;
import com.estimaciones.service.EstimacionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/estimaciones")
public class EstimacionController {
    private final EstimacionService estimacionService;

    @Autowired
    public EstimacionController(EstimacionService estimacionService) {
        this.estimacionService = estimacionService;
    }

    @PostMapping
    public ResponseEntity<Estimacion> crearEstimacion(@RequestBody Estimacion estimacion) {
        Estimacion guardada = estimacionService.guardarEstimacion(estimacion);
        return ResponseEntity.ok(guardada);
    }
}
