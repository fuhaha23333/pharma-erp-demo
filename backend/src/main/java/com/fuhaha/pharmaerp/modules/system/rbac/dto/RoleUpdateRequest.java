package com.fuhaha.pharmaerp.modules.system.rbac.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "修改角色请求")
public class RoleUpdateRequest {

    @NotBlank
    @Size(max = 100)
    private String roleName;

    @NotBlank
    @Pattern(regexp = "NORMAL|HIGH", message = "风险等级只能为NORMAL或HIGH")
    private String riskLevel;

    @NotBlank
    @Pattern(regexp = "ACTIVE|DISABLED", message = "状态只能为ACTIVE或DISABLED")
    private String status;

    @Size(max = 500)
    private String description;

    @NotBlank
    @Size(max = 500)
    private String changeReason;
}
