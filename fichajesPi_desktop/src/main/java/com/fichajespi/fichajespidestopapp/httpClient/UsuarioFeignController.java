package com.fichajespi.fichajespidestopapp.httpClient;

import feign.Param;
import feign.RequestLine;

public interface UsuarioFeignController {
    @RequestLine("GET /public/usuario/id/{numero}")
    UsuarioResponse getIdByNumero(@Param("numero") String numero);
}
