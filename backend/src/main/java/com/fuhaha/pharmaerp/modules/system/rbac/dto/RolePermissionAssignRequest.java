package com.fuhaha.pharmaerp.modules.system.rbac.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.LinkedHashSet;
import java.util.Set;
import lombok.Data;

@Data
@Schema(description = "替换角色权限请求")
public class RolePermissionAssignRequest {

    @NotNull
    @Size(max = 500)
    @Schema(description = "目标权限ID集合")
    private Set<Long> permissionIds = new LinkedHashSet<>();

    @NotBlank
    @Size(max = 500)
    @Schema(description = "配置原因")
    private String reason;
}
