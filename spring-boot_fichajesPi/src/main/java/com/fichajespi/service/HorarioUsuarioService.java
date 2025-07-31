package com.fichajespi.service;

import com.fichajespi.dto.HorarioUsuarioDTO;
import com.fichajespi.entity.HorarioUsuario;
import com.fichajespi.entity.Usuario;
import com.fichajespi.repository.HorarioUsuarioRepository;
import com.fichajespi.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional
public class HorarioUsuarioService {
    
    @Autowired
    private HorarioUsuarioRepository horarioUsuarioRepository;
    
    @Autowired
    private UsuarioRepository usuarioRepository;
    
    /**
     * Obtener todos los horarios de un usuario
     */
    public List<HorarioUsuarioDTO> getHorariosByUsuario(Long usuarioId) {
        return horarioUsuarioRepository.findByUsuarioIdAndActivoTrue(usuarioId)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Obtener horarios de un usuario para un día específico
     */
    public List<HorarioUsuarioDTO> getHorariosByUsuarioYDia(Long usuarioId, Integer diaSemana) {
        Optional<Usuario> usuario = usuarioRepository.findById(usuarioId);
        if (!usuario.isPresent()) {
            throw new RuntimeException("Usuario no encontrado");
        }
        
        return horarioUsuarioRepository.findByUsuarioAndDiaSemanaAndActivoTrueOrderByTurnoNumeroAsc(usuario.get(), diaSemana)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Crear o actualizar horarios para un usuario en un día específico
     */
    public List<HorarioUsuarioDTO> saveHorariosUsuarioDia(HorarioUsuarioDTO.CreateUpdateDTO createUpdateDTO) {
        Optional<Usuario> usuarioOpt = usuarioRepository.findById(createUpdateDTO.getUsuarioId());
        if (!usuarioOpt.isPresent()) {
            throw new RuntimeException("Usuario no encontrado");
        }
        
        Usuario usuario = usuarioOpt.get();
        
        // Desactivar horarios existentes para este día
        horarioUsuarioRepository.desactivarHorariosPorUsuarioYDia(usuario, createUpdateDTO.getDiaSemana());
        
        // Crear nuevos horarios
        List<HorarioUsuario> nuevosHorarios = createUpdateDTO.getTurnos().stream()
                .map(turnoDTO -> {
                    HorarioUsuario horario = new HorarioUsuario();
                    horario.setUsuario(usuario);
                    horario.setDiaSemana(createUpdateDTO.getDiaSemana());
                    horario.setTurnoNumero(turnoDTO.getTurnoNumero());
                    horario.setHoraInicio(turnoDTO.getHoraInicio());
                    horario.setHoraFin(turnoDTO.getHoraFin());
                    horario.setDescripcion(turnoDTO.getDescripcion());
                    horario.setActivo(true);
                    return horario;
                })
                .collect(Collectors.toList());
        
        // Validar horarios
        validarHorarios(nuevosHorarios);
        
        // Guardar
        List<HorarioUsuario> horariosGuardados = horarioUsuarioRepository.saveAll(nuevosHorarios);
        
        return horariosGuardados.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Eliminar (desactivar) horario específico
     */
    public void deleteHorario(Long horarioId) {
        Optional<HorarioUsuario> horario = horarioUsuarioRepository.findById(horarioId);
        if (horario.isPresent()) {
            HorarioUsuario h = horario.get();
            h.setActivo(false);
            horarioUsuarioRepository.save(h);
        }
    }
    
    /**
     * Obtener todos los horarios activos
     */
    public List<HorarioUsuarioDTO> getAllHorariosActivos() {
        return horarioUsuarioRepository.findAllActivosOrdenados()
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Obtener usuarios con horarios para un día específico
     */
    public List<Usuario> getUsuariosConHorarioPorDia(Integer diaSemana) {
        return horarioUsuarioRepository.findUsuariosConHorarioPorDia(diaSemana);
    }
    
    /**
     * Validar que los horarios no se solapen y sean consistentes
     */
    private void validarHorarios(List<HorarioUsuario> horarios) {
        for (int i = 0; i < horarios.size(); i++) {
            HorarioUsuario horario1 = horarios.get(i);
            
            // Validar que hora inicio sea menor que hora fin
            if (horario1.getHoraInicio().isAfter(horario1.getHoraFin())) {
                throw new RuntimeException("La hora de inicio debe ser menor que la hora de fin para el turno " + horario1.getTurnoNumero());
            }
            
            // Validar solapamiento con otros turnos del mismo día
            for (int j = i + 1; j < horarios.size(); j++) {
                HorarioUsuario horario2 = horarios.get(j);
                
                if (horariosSeSuperponen(horario1, horario2)) {
                    throw new RuntimeException("Los turnos " + horario1.getTurnoNumero() + " y " + horario2.getTurnoNumero() + " se superponen");
                }
            }
        }
    }
    
    /**
     * Verificar si dos horarios se superponen
     */
    private boolean horariosSeSuperponen(HorarioUsuario h1, HorarioUsuario h2) {
        return h1.getHoraInicio().isBefore(h2.getHoraFin()) && h2.getHoraInicio().isBefore(h1.getHoraFin());
    }
    
    /**
     * Convertir entidad a DTO
     */
    private HorarioUsuarioDTO convertToDTO(HorarioUsuario horario) {
        return new HorarioUsuarioDTO(
                horario.getId(),
                horario.getUsuario().getId(),
                horario.getUsuario().getNombreEmpleado(),
                horario.getDiaSemana(),
                horario.getTurnoNumero(),
                horario.getHoraInicio(),
                horario.getHoraFin(),
                horario.getActivo(),
                horario.getDescripcion()
        );
    }
    
    /**
     * Obtener horario específico por ID
     */
    public HorarioUsuarioDTO getHorarioById(Long horarioId) {
        Optional<HorarioUsuario> horario = horarioUsuarioRepository.findById(horarioId);
        if (!horario.isPresent()) {
            throw new RuntimeException("Horario no encontrado");
        }
        return convertToDTO(horario.get());
    }
    
    /**
     * Verificar si un usuario tiene horarios configurados
     */
    public boolean usuarioTieneHorarios(Long usuarioId) {
        List<HorarioUsuario> horarios = horarioUsuarioRepository.findByUsuarioIdAndActivoTrue(usuarioId);
        return !horarios.isEmpty();
    }
}
