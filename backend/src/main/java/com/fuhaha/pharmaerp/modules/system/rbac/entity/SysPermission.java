package com.fuhaha.pharmaerp.modules.system.rbac.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fuhaha.pharmaerp.common.entity.BaseAuditEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_permission")
public class SysPermission extends BaseAuditEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long parentId;

    private String permissionCode;

    private String permissionName;

    private String permissionType;

    private String moduleCode;

    private String resourceKey;

    private String routePath;

    private String httpMethod;

    private String apiPattern;

    private String status;

    private Integer sortOrder;

    private String description;
}
