package com.fichajespi;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.TimeZone;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.boot.autoconfigure.domain.EntityScan;

import com.fichajespi.dto.converter.UsuarioDtoConverter;
import com.fichajespi.dto.entity.UsuarioDto;
import com.fichajespi.entity.Rol;
import com.fichajespi.entity.Usuario;
import com.fichajespi.security.enums.RolNombre;
import com.fichajespi.service.RolService;
import com.fichajespi.service.UsuarioService;

@SpringBootApplication
@ComponentScan({"com.fichajespi", "com.estimaciones"})
@EnableJpaRepositories({"com.fichajespi.repository", "com.estimaciones.repository"})
@EntityScan({"com.fichajespi.entity", "com.estimaciones.model"})
@EnableScheduling
public class Application {

	@Autowired
	RolService rolService;
	@Autowired
	UsuarioService usuarioService;
	@Autowired
	UsuarioDtoConverter dtoConverter;

	@PostConstruct
	public void init() {
		// Configurar zona horaria por defecto para toda la aplicación
		TimeZone.setDefault(TimeZone.getTimeZone("Europe/Madrid"));
		System.out.println("Spring boot application running in Europe/Madrid timezone :"
				+ new Date());

		/*
		 * Crear los roles si es la primera vez que se ejecuta la app y la tabla no
		 * tiene datos
		 */
		List<Rol> roles = rolService.list();
		if (roles.size() == 0) {
			Rol rolUser = new Rol();
			Rol rolRrhh = new Rol();
//			Rol rolAdmin = new Rol();
			rolUser.setRolNombre(RolNombre.ROLE_USER);
			rolRrhh.setRolNombre(RolNombre.ROLE_RRHH);
//			rolAdmin.setRolNombre(RolNombre.ROLE_ADMIN);
			rolService.save(rolUser);
			rolService.save(rolRrhh);
//			rolService.save(rolAdmin);
			System.out.println("Roles creados");
		} else {
			System.out.println("Roles ya existen");
		}

		
//		Creamos el usuario admin si no existe para poder tener un usuario con privilegios
		String adminCredential = "fichajesPi000";

		Usuario admin = usuarioService.findByNumero(adminCredential).orElse(null);
		if (admin == null) {
			System.out.println("No existe usuario admin");
			
			List<String> rolesAdmin = new ArrayList<>();
//			rolesAdmin.add("admin");
			rolesAdmin.add("rrhh");
			rolesAdmin.add("user");
			
			UsuarioDto adminDto = new UsuarioDto().builder()
					.nombreEmpleado("AdminFichajesPi")
					.numero(adminCredential)
					.password(adminCredential)
					.email("fichajespi@fichajespi.com")
					.roles(rolesAdmin)
					.dni("zzz")
					.build();

			admin = dtoConverter.transformNewAdmin(adminDto);
			usuarioService.save(admin);
			System.out.println(
					"Usuario admin creado con número: " + adminCredential + " y pass: "
							+ adminCredential);
		} else {
			System.out.println("Existe usuario admin");
		}

	}

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

}
