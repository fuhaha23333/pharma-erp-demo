package com.fuhaha.pharmaerp.modules.system.rbac.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.LinkedHashSet;
import java.util.Set;
import lombok.Data;

@Data
@Schema(description = "替换用户有效角色请求")
public class UserRoleAssignRequest {

    @NotNull
    @Size(max = 30)
    @Schema(description = "目标角色ID集合；空集合表示撤销全部角色")
    private Set<Long> roleIds = new LinkedHashSet<>();

    @NotBlank
    @Size(max = 500)
    @Schema(description = "授权或撤销原因")
    private String reason;
}
