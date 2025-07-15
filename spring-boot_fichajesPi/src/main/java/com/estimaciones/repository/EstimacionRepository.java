package com.estimaciones.repository;

import com.estimaciones.model.Estimacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EstimacionRepository extends JpaRepository<Estimacion, Long> {
    // Métodos personalizados si se necesitan
}
