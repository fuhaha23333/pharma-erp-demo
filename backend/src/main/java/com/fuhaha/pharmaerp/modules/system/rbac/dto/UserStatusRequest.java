package com.fuhaha.pharmaerp.modules.system.rbac.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "变更用户状态请求")
public class UserStatusRequest {

    @NotBlank
    @Pattern(regexp = "ACTIVE|DISABLED", message = "状态只能为ACTIVE或DISABLED")
    @Schema(description = "目标状态", allowableValues = {"ACTIVE", "DISABLED"})
    private String status;

    @NotBlank
    @Size(max = 500)
    @Schema(description = "状态变更原因")
    private String reason;
}
