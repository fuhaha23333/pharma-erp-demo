package com.fuhaha.pharmaerp.modules.system.rbac.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.Data;

@Data
@Schema(description = "用户详情")
public class UserVO {

    private Long id;

    private String username;

    private String displayName;

    private Long departmentId;

    private String departmentName;

    private String mobile;

    private String email;

    private String status;

    private LocalDateTime lastLoginAt;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    private List<RoleSimpleVO> roles = new ArrayList<>();
}
