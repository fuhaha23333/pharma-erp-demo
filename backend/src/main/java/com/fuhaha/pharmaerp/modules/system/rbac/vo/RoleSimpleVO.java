package com.fuhaha.pharmaerp.modules.system.rbac.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "角色摘要")
public class RoleSimpleVO {

    private Long id;

    private String roleCode;

    private String roleName;

    private String riskLevel;

    private String status;
}
