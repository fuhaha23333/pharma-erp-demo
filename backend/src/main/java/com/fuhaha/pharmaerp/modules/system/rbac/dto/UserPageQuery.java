package com.fuhaha.pharmaerp.modules.system.rbac.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "用户分页查询")
public class UserPageQuery {

    @Min(1)
    private Long pageNo = 1L;

    @Min(1)
    @Max(100)
    private Long pageSize = 20L;

    @Size(max = 64)
    private String username;

    @Size(max = 100)
    private String displayName;

    @Size(max = 16)
    @Pattern(regexp = "ACTIVE|DISABLED|LOCKED", message = "用户状态非法")
    private String status;

    private Long departmentId;
}
