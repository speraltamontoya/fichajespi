package com.estimaciones.service;

import com.estimaciones.model.Estimacion;
import com.estimaciones.repository.EstimacionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class EstimacionService {
    private final EstimacionRepository estimacionRepository;

    @Autowired
    public EstimacionService(EstimacionRepository estimacionRepository) {
        this.estimacionRepository = estimacionRepository;
    }

    public Estimacion guardarEstimacion(Estimacion estimacion) {
        return estimacionRepository.save(estimacion);
    }
}
