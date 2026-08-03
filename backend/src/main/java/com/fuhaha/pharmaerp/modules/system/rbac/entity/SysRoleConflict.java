package com.fuhaha.pharmaerp.modules.system.rbac.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fuhaha.pharmaerp.common.entity.BaseAuditEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_role_conflict")
public class SysRoleConflict extends BaseAuditEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long roleAId;

    private Long roleBId;

    private String conflictScope;

    private String reason;

    private String status;
}
