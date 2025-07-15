package com.fichajespi.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fichajespi.service.UsuarioService;

@RestController
@RequestMapping("/public/usuario")
public class PublicUsuarioController {

    @Autowired
    UsuarioService usuarioService;

    public static class UsuarioIdResponse {
        public Long id;
        public UsuarioIdResponse(Long id) { this.id = id; }
    }

    @GetMapping("/id/{numero}")
    public ResponseEntity<?> getUsuarioIdByNumero(@PathVariable String numero) {
        com.fichajespi.entity.Usuario usuario = null;
        try {
            usuario = usuarioService.findByNumero(numero).orElse(null);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error consultando usuario: " + e.getMessage());
        }
        if (usuario != null) {
            return ResponseEntity.ok(new UsuarioIdResponse(usuario.getId()));
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
