package com.fichajespi.fichajespidestopapp.tools;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Utilidad para logging con timestamp
 */
public class Logger {
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS");
    
    public static void log(String message) {
        String timestamp = LocalDateTime.now().format(FORMATTER);
        System.out.println("[" + timestamp + "] " + message);
    }
    
    public static void debug(String message) {
        log("[DEBUG] " + message);
    }
    
    public static void info(String message) {
        log("[INFO] " + message);
    }
    
    public static void warning(String message) {
        log("[WARNING] " + message);
    }
    
    public static void error(String message) {
        log("[ERROR] " + message);
    }
}
