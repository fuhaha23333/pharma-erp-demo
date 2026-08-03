package com.fuhaha.pharmaerp.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    public static final String BASIC_AUTH_SCHEME = "basicAuth";

    @Bean
    public OpenAPI pharmaErpOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("药品供应链资质审核与追溯系统 API")
                        .version("phase-1")
                        .description("第一阶段后端接口：用户、角色、基础权限、供应商审核和药品追溯"))
                .addSecurityItem(new SecurityRequirement().addList(BASIC_AUTH_SCHEME))
                .components(new Components().addSecuritySchemes(
                        BASIC_AUTH_SCHEME,
                        new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("basic")));
    }
}
