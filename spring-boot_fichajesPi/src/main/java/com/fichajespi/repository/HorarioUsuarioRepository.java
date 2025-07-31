package com.fichajespi.repository;

import com.fichajespi.entity.HorarioUsuario;
import com.fichajespi.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface HorarioUsuarioRepository extends JpaRepository<HorarioUsuario, Long> {
    
    /**
     * Obtener todos los horarios de un usuario específico
     */
    List<HorarioUsuario> findByUsuarioAndActivoTrueOrderByDiaSemanaAscTurnoNumeroAsc(Usuario usuario);
    
    /**
     * Obtener horarios de un usuario para un día específico de la semana
     */
    List<HorarioUsuario> findByUsuarioAndDiaSemanaAndActivoTrueOrderByTurnoNumeroAsc(Usuario usuario, Integer diaSemana);
    
    /**
     * Obtener todos los horarios activos ordenados por usuario y día
     */
    @Query("SELECT h FROM HorarioUsuario h WHERE h.activo = true ORDER BY h.usuario.nombreEmpleado, h.diaSemana, h.turnoNumero")
    List<HorarioUsuario> findAllActivosOrdenados();
    
    /**
     * Verificar si existe un horario para usuario, día y turno específico
     */
    boolean existsByUsuarioAndDiaSemanaAndTurnoNumeroAndActivoTrue(Usuario usuario, Integer diaSemana, Integer turnoNumero);
    
    /**
     * Obtener horarios por usuario ID
     */
    @Query("SELECT h FROM HorarioUsuario h WHERE h.usuario.id = :usuarioId AND h.activo = true ORDER BY h.diaSemana, h.turnoNumero")
    List<HorarioUsuario> findByUsuarioIdAndActivoTrue(@Param("usuarioId") Long usuarioId);
    
    /**
     * Eliminar (desactivar) todos los horarios de un usuario para un día específico
     */
    @Modifying
    @Query("UPDATE HorarioUsuario h SET h.activo = false WHERE h.usuario = :usuario AND h.diaSemana = :diaSemana")
    void desactivarHorariosPorUsuarioYDia(@Param("usuario") Usuario usuario, @Param("diaSemana") Integer diaSemana);
    
    /**
     * Obtener usuarios que tienen horarios configurados para un día específico
     */
    @Query("SELECT DISTINCT h.usuario FROM HorarioUsuario h WHERE h.diaSemana = :diaSemana AND h.activo = true")
    List<Usuario> findUsuariosConHorarioPorDia(@Param("diaSemana") Integer diaSemana);
}
