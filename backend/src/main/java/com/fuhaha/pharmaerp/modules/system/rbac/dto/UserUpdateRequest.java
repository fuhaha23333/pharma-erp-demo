package com.fuhaha.pharmaerp.modules.system.rbac.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "修改用户请求")
public class UserUpdateRequest {

    @NotBlank
    @Size(max = 100)
    @Schema(description = "用户姓名")
    private String displayName;

    @NotNull
    @Schema(description = "所属部门ID")
    private Long departmentId;

    @Size(max = 32)
    @Schema(description = "手机号码")
    private String mobile;

    @Email
    @Size(max = 128)
    @Schema(description = "电子邮箱")
    private String email;

    @NotBlank
    @Size(max = 500)
    @Schema(description = "修改原因")
    private String changeReason;
}
