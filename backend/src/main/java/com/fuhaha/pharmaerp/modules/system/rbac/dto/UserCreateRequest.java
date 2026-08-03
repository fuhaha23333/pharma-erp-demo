package com.fuhaha.pharmaerp.modules.system.rbac.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "创建用户请求")
public class UserCreateRequest {

    @NotBlank
    @Size(max = 64)
    @Pattern(regexp = "^[A-Za-z0-9._-]+$", message = "账号只能包含字母、数字、点、下划线和连字符")
    @Schema(description = "登录账号", example = "quality.manager")
    private String username;

    @NotBlank
    @Size(max = 100)
    @Schema(description = "用户姓名", example = "质量负责人")
    private String displayName;

    @NotBlank
    @Size(min = 8, max = 72)
    @Schema(description = "初始密码，仅在请求中传输，数据库保存BCrypt哈希", example = "ChangeMe123!")
    private String initialPassword;

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
}
