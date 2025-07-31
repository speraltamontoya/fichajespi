package com.fichajespi.controller;

import com.fichajespi.dto.HorarioUsuarioDTO;
import com.fichajespi.entity.Usuario;
import com.fichajespi.service.HorarioUsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/horarios")
@CrossOrigin(origins = "*")
public class HorarioUsuarioController {
    
    @Autowired
    private HorarioUsuarioService horarioUsuarioService;
    
    /**
     * Obtener todos los horarios de un usuario
     */
    @GetMapping("/usuario/{usuarioId}")
    public ResponseEntity<List<HorarioUsuarioDTO>> getHorariosByUsuario(@PathVariable Long usuarioId) {
        try {
            List<HorarioUsuarioDTO> horarios = horarioUsuarioService.getHorariosByUsuario(usuarioId);
            return ResponseEntity.ok(horarios);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    /**
     * Obtener horarios de un usuario para un día específico
     */
    @GetMapping("/usuario/{usuarioId}/dia/{diaSemana}")
    public ResponseEntity<List<HorarioUsuarioDTO>> getHorariosByUsuarioYDia(
            @PathVariable Long usuarioId, 
            @PathVariable Integer diaSemana) {
        try {
            List<HorarioUsuarioDTO> horarios = horarioUsuarioService.getHorariosByUsuarioYDia(usuarioId, diaSemana);
            return ResponseEntity.ok(horarios);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    /**
     * Crear o actualizar horarios para un usuario en un día específico
     */
    @PostMapping("/usuario/{usuarioId}/dia/{diaSemana}")
    public ResponseEntity<Map<String, Object>> saveHorariosUsuarioDia(
            @PathVariable Long usuarioId,
            @PathVariable Integer diaSemana,
            @RequestBody HorarioUsuarioDTO.CreateUpdateDTO createUpdateDTO) {
        try {
            // Asegurar que los IDs coincidan
            createUpdateDTO.setUsuarioId(usuarioId);
            createUpdateDTO.setDiaSemana(diaSemana);
            
            List<HorarioUsuarioDTO> horarios = horarioUsuarioService.saveHorariosUsuarioDia(createUpdateDTO);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Horarios guardados correctamente");
            response.put("horarios", horarios);
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Error interno del servidor");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
    
    /**
     * Eliminar (desactivar) un horario específico
     */
    @DeleteMapping("/{horarioId}")
    public ResponseEntity<Map<String, Object>> deleteHorario(@PathVariable Long horarioId) {
        try {
            horarioUsuarioService.deleteHorario(horarioId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Horario eliminado correctamente");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Error al eliminar horario");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
    
    /**
     * Obtener todos los horarios activos (para administradores)
     */
    @GetMapping("/todos")
    public ResponseEntity<List<HorarioUsuarioDTO>> getAllHorariosActivos() {
        try {
            List<HorarioUsuarioDTO> horarios = horarioUsuarioService.getAllHorariosActivos();
            return ResponseEntity.ok(horarios);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    /**
     * Obtener usuarios que tienen horarios para un día específico
     */
    @GetMapping("/usuarios-con-horario/dia/{diaSemana}")
    public ResponseEntity<List<Usuario>> getUsuariosConHorarioPorDia(@PathVariable Integer diaSemana) {
        try {
            List<Usuario> usuarios = horarioUsuarioService.getUsuariosConHorarioPorDia(diaSemana);
            return ResponseEntity.ok(usuarios);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    /**
     * Obtener un horario específico por ID
     */
    @GetMapping("/{horarioId}")
    public ResponseEntity<HorarioUsuarioDTO> getHorarioById(@PathVariable Long horarioId) {
        try {
            HorarioUsuarioDTO horario = horarioUsuarioService.getHorarioById(horarioId);
            return ResponseEntity.ok(horario);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    /**
     * Verificar si un usuario tiene horarios configurados
     */
    @GetMapping("/usuario/{usuarioId}/tiene-horarios")
    public ResponseEntity<Map<String, Object>> usuarioTieneHorarios(@PathVariable Long usuarioId) {
        try {
            boolean tieneHorarios = horarioUsuarioService.usuarioTieneHorarios(usuarioId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("usuarioId", usuarioId);
            response.put("tieneHorarios", tieneHorarios);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    /**
     * Obtener días de la semana disponibles (utilidad)
     */
    @GetMapping("/dias-semana")
    public ResponseEntity<List<Map<String, Object>>> getDiasSemana() {
        List<Map<String, Object>> dias = List.of(
            Map.of("id", 1, "nombre", "Lunes"),
            Map.of("id", 2, "nombre", "Martes"),
            Map.of("id", 3, "nombre", "Miércoles"),
            Map.of("id", 4, "nombre", "Jueves"),
            Map.of("id", 5, "nombre", "Viernes"),
            Map.of("id", 6, "nombre", "Sábado"),
            Map.of("id", 7, "nombre", "Domingo")
        );
        return ResponseEntity.ok(dias);
    }
}
