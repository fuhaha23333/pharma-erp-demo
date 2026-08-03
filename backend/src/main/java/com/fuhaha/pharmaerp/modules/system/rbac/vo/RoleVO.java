package com.fuhaha.pharmaerp.modules.system.rbac.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.Data;

@Data
@Schema(description = "角色详情")
public class RoleVO {

    private Long id;

    private String roleCode;

    private String roleName;

    private String riskLevel;

    private String description;

    private String status;

    private Integer isBuiltin;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    private List<PermissionVO> permissions = new ArrayList<>();
}
