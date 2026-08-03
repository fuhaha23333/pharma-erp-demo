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
@TableName("sys_user_role")
public class SysUserRole extends BaseAuditEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private Long roleId;

    private String status;

    private LocalDateTime validFrom;

    private LocalDateTime validTo;

    private Long sourceAssignmentId;
}
