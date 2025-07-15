package com.fichajespi.fichajespidestopapp.tools;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class BackendConfig {
    private static final String DEFAULT_URL = "http://localhost:8080";
    private static final String ENV_VAR = "BACKEND_URL";
    private static final String PROP_FILE = "config.properties";
    private static final String PROP_KEY = "backend.url";

    public static String getBackendUrl(String[] args) {
        // 1. Argumento de línea de comandos
        for (String arg : args) {
            if (arg.startsWith("--backendUrl=")) {
                return arg.substring("--backendUrl=".length());
            }
        }
        // 2. Variable de entorno
        String env = System.getenv(ENV_VAR);
        if (env != null && !env.isEmpty()) {
            return env;
        }
        // 3. Fichero de propiedades
        try (FileInputStream fis = new FileInputStream(PROP_FILE)) {
            Properties props = new Properties();
            props.load(fis);
            String prop = props.getProperty(PROP_KEY);
            if (prop != null && !prop.isEmpty()) {
                return prop;
            }
        } catch (IOException ignored) {}
        // 4. Por defecto
        return DEFAULT_URL;
    }
}
