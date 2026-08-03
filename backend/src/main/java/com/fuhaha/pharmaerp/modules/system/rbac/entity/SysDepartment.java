package com.fuhaha.pharmaerp.modules.system.rbac.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fuhaha.pharmaerp.common.entity.BaseAuditEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_department")
public class SysDepartment extends BaseAuditEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long parentId;

    private String departmentCode;

    private String departmentName;

    private String departmentType;

    private String status;

    private Integer sortOrder;
}
