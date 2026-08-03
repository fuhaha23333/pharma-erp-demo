package com.fuhaha.pharmaerp.modules.system.rbac.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fuhaha.pharmaerp.common.entity.BaseAuditEntity;
import java.time.LocalDateTime;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_user")
public class SysUser extends BaseAuditEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String username;

    private String displayName;

    private String passwordHash;

    private Long departmentId;

    private String mobile;

    private String email;

    private String status;

    private Integer failedLoginCount;

    private LocalDateTime lockedUntil;

    private LocalDateTime lastLoginAt;
}
