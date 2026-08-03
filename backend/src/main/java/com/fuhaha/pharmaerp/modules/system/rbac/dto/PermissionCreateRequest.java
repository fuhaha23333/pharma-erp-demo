package com.fuhaha.pharmaerp.modules.system.rbac.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "创建基础权限请求")
public class PermissionCreateRequest {

    private Long parentId;

    @NotBlank
    @Size(max = 64)
    @Pattern(regexp = "^[A-Z][A-Z0-9_]*$", message = "权限编码必须为大写字母、数字和下划线")
    private String permissionCode;

    @NotBlank
    @Size(max = 160)
    private String permissionName;

    @NotBlank
    @Pattern(regexp = "MENU|PAGE|BUTTON|DATA|ACTION", message = "权限类型非法")
    @Schema(allowableValues = {"MENU", "PAGE", "BUTTON", "DATA", "ACTION"})
    private String permissionType;

    @NotBlank
    @Size(max = 32)
    private String moduleCode;

    @Size(max = 160)
    private String resourceKey;

    @Size(max = 255)
    private String routePath;

    @Size(max = 16)
    private String httpMethod;

    @Size(max = 255)
    private String apiPattern;

    private Integer sortOrder = 0;

    @Size(max = 500)
    private String description;
}
