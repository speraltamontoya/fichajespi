package com.fichajespi.controller;

import com.fichajespi.fichajespidestopapp.entity.Usuario;
import com.fichajespi.fichajespidestopapp.repository.UsuarioRepository;
import com.fichajespi.fichajespidestopapp.service.EmailService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.SecureRandom;

@RestController
@RequestMapping("/admin/usuarios")
public class AdminUsuarioController {

    @Autowired
    private UsuarioRepository usuarioRepository;
    @Autowired
    private EmailService emailService;

    private static final String CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    private static final int PASS_LENGTH = 10;

    private String generarPasswordAleatoria() {
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder(PASS_LENGTH);
        for (int i = 0; i < PASS_LENGTH; i++) {
            sb.append(CHARS.charAt(random.nextInt(CHARS.length())));
        }
        return sb.toString();
    }

    // 1. Resetear y enviar por email
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/{id}/reset-password")
    public ResponseEntity<?> resetPasswordAndSendEmail(@PathVariable Long id) {
        Usuario usuario = usuarioRepository.findById(id).orElse(null);
        if (usuario == null) return ResponseEntity.notFound().build();
        String nuevaPassword = generarPasswordAleatoria();
        usuario.setPassword(nuevaPassword); // Asegúrate de que se codifica en el servicio/entidad
        usuarioRepository.save(usuario);
        emailService.sendPasswordEmail(usuario.getEmail(), nuevaPassword);
        return ResponseEntity.ok().build();
    }

    // 2. Establecer manualmente
    public static class SetPasswordRequest {
        public String nuevaPassword;
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/{id}/set-password")
    public ResponseEntity<?> setPasswordManual(@PathVariable Long id, @RequestBody SetPasswordRequest req) {
        Usuario usuario = usuarioRepository.findById(id).orElse(null);
        if (usuario == null) return ResponseEntity.notFound().build();
        usuario.setPassword(req.nuevaPassword); // Asegúrate de que se codifica en el servicio/entidad
        usuarioRepository.save(usuario);
        return ResponseEntity.ok().build();
    }
}
