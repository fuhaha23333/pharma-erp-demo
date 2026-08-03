package com.fuhaha.pharmaerp.modules.system.rbac.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "创建角色请求")
public class RoleCreateRequest {

    @NotBlank
    @Size(max = 32)
    @Pattern(regexp = "^[A-Z][A-Z0-9_]*$", message = "角色编码必须为大写字母、数字和下划线")
    @Schema(description = "角色编码", example = "QUALITY_HEAD")
    private String roleCode;

    @NotBlank
    @Size(max = 100)
    @Schema(description = "角色名称", example = "质量负责人")
    private String roleName;

    @NotBlank
    @Pattern(regexp = "NORMAL|HIGH", message = "风险等级只能为NORMAL或HIGH")
    @Schema(description = "风险等级", allowableValues = {"NORMAL", "HIGH"})
    private String riskLevel;

    @Size(max = 500)
    private String description;
}
