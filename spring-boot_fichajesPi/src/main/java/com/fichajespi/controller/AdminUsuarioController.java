package com.fichajespi.controller;

import com.fichajespi.entity.Usuario;
import com.fichajespi.repository.UsuarioRepository;
import com.fichajespi.mail.EmailService;
import org.springframework.security.crypto.password.PasswordEncoder;


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
    @Autowired
    private PasswordEncoder passwordEncoder;

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
    //@PreAuthorize("hasRole(RRHH)")
    @PostMapping("/{id}/reset-password")
    public ResponseEntity<?> resetPasswordAndSendEmail(@PathVariable Long id) {
        Usuario usuario = usuarioRepository.findById(id).orElse(null);
        if (usuario == null) return ResponseEntity.notFound().build();
        String nuevaPassword = generarPasswordAleatoria();
        usuario.setPassword(passwordEncoder.encode(nuevaPassword));
        usuarioRepository.save(usuario);
        StringBuilder body = new StringBuilder("Sus credenciales de acceso a FichajesPi han sido reseteadas:\n\n");
        body.append(String.format("Número de empleado: %s \n", usuario.getNumero()));
        body.append(String.format("Contraseña: %s \n\n", nuevaPassword));
        body.append("Puede cambiar su contraseña desde la aplicación.");
        emailService.sendEmail(usuario.getEmail(), "Contraseña reseteada en FichajesPi", body.toString());
        return ResponseEntity.ok().build();
    }

    // 2. Establecer manualmente
    public static class SetPasswordRequest {
        public String password;
    }

    //@PreAuthorize("hasRole(RRHH)")
    @PostMapping("/{id}/set-password")
    public ResponseEntity<?> setPasswordManual(@PathVariable Long id, @RequestBody SetPasswordRequest req) {
        Usuario usuario = usuarioRepository.findById(id).orElse(null);
        if (usuario == null) return ResponseEntity.notFound().build();
        usuario.setPassword(passwordEncoder.encode(req.password));
        usuarioRepository.save(usuario);
        return ResponseEntity.ok().build();
    }
}
